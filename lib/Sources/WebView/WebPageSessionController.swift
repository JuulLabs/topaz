import BluetoothClient
import BluetoothEngine
import Foundation
import JsMessage
import Navigation
import WebKit

/**
 Owns the session-scoped machinery for a single web page: navigation delegates,
 script handler attach/detach, and Js context swaps.

 Created and retained by `WebPageModel` so that the web view's lifecycle is bound
 to the model layer rather than to SwiftUI view mount/unmount. Teardown happens
 via an explicit `deinitialize(webView:)` call and is safe to invoke repeatedly.
 */
@MainActor
class WebPageSessionController: NSObject, NavigationEngineDelegate {
    private let world: WKContentWorld = .page
    private var messageProcessorFactory: JsMessageProcessorFactory!
    private var contextId: JsContextIdentifier!
    private var scriptHandler: ScriptHandler?
    private var deliveryQueue: JsEventDeliveryQueue?
    private weak var viewModel: WebPageModel?
    private var lastLoadedURL: URL?
    private var navigationEngine: NavigationEngine?
    private var authorize: () async -> Bool = { false }

    /// Serializes cross-origin context swaps. Each swap chains off the previous one so that
    /// detach/attach pairs cannot interleave or finish out of order across rapid navigations.
    private var pendingContextSwap: Task<Void, Never>?

    override init() {}

    func initialize(webView: WKWebView, model: WebPageModel) {
        self.viewModel = model
        self.messageProcessorFactory = model.messageProcessorFactory
        self.contextId = model.contextId

        self.navigationEngine = NavigationEngine(navigator: model.navigator)
        self.navigationEngine?.delegate = self
        webView.navigationDelegate = navigationEngine
        webView.uiDelegate = navigationEngine
        webView.customUserAgent = model.customUserAgent
        model.navigator.startObservingNavigationState(of: webView)

        authorize = { [weak model] in
            await model?.requestAuthorization() ?? false
        }
    }

    func deinitialize(webView: WKWebView) {
        pendingContextSwap?.cancel()
        pendingContextSwap = nil
        viewModel?.navigator.stopObservingNavigationState()
        navigationEngine = nil
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        viewModel = nil
        lastLoadedURL = nil
        detachOldHandler(from: webView)
        authorize = { false }
    }

    func update(webView: WKWebView, model: WebPageModel) {
        webView.customUserAgent = model.customUserAgent
        guard model.url != lastLoadedURL else { return }
        lastLoadedURL = model.url
        webView.load(URLRequest(url: model.url))
    }

    private func attachNewHandler(to webView: WKWebView) {
        // Deliveries into the page go through a bounded, order-preserving queue so a
        // slow or suspended page can never stall the tab's engine event loop. Overflow
        // means the page has been unresponsive under sustained traffic: report it so
        // the owner can tear the session down rather than lose data silently.
        let queue = JsEventDeliveryQueue(
            deliver: { [weak webView, world] event in
                guard let webView else {
                    return .failure(JsEventDeliveryError.cancelled)
                }
                return await webView.sendTopazEvent(event, in: world)
            },
            onOverflow: { [weak self] in
                self?.viewModel?.eventDeliveryDidOverflow()
            }
        )
        self.deliveryQueue = queue
        let context = webView.createContext(contextId: contextId, deliveryQueue: queue)
        let newHandler = ScriptHandler(context: context, factory: messageProcessorFactory, authorize: authorize)
        self.scriptHandler = newHandler
        webView.attachScriptHandler(newHandler, in: world)
    }

    private func cancelDeliveryQueue() {
        deliveryQueue?.cancel()
        deliveryQueue = nil
    }

    private func detachOldHandler(from webView: WKWebView) {
        cancelDeliveryQueue()
        guard let scriptHandler else { return }
        scriptHandler.detachProcessors()
        webView.detachScriptHandler(scriptHandler, in: world)
        self.scriptHandler = nil
    }

    private func detachOldHandlerAndWait(from webView: WKWebView) async {
        cancelDeliveryQueue()
        guard let scriptHandler else { return }
        await scriptHandler.detachProcessorsAndWait()
        webView.detachScriptHandler(scriptHandler, in: world)
        self.scriptHandler = nil
    }

    // MARK: - NavigationEngineDelegate

    public func didInitiateNavigation(_ navigation: NavigationItem, in webView: WKWebView) {
        switch navigation.request.kind {
        case .newWindow:
            // Will trigger load of an entire new tab container so no need for any action
            break
        case .sameOrigin:
            // Carry over the same Js context to keep BLE connections alive
            break
        case .crossOrigin:
            // Tear down and spin up a new Js context for this new web page.
            // Chain off any in-flight swap so detach/attach pairs stay ordered, and supersede it
            // so a stale navigation can't attach a context after a newer one has started.
            // TODO: move this to be synchronous work on decidePolicyFor:navigationAction instead
            let newContextId = contextId.withUrl(navigation.request.url)
            let previousSwap = pendingContextSwap
            previousSwap?.cancel()
            pendingContextSwap = Task { @MainActor [weak self] in
                _ = await previousSwap?.value
                guard let self, !Task.isCancelled else { return }
                await self.detachOldHandlerAndWait(from: webView)
                guard !Task.isCancelled, self.viewModel != nil else { return }
                self.contextId = newContextId
                self.attachNewHandler(to: webView)
            }
        }
    }

    public func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView) {
        viewModel?.didBeginLoading(url: navigation.request.url)
    }

    public func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView) {
        guard let currentURL = webView.url else { return }
        lastLoadedURL = currentURL
        viewModel?.didFinishLoading(url: currentURL)
        // TODO: detect if the webpage has `overflow: hidden;` and `height: 100%` and set viewModel?.isFullScreenNonScrollable accordingly
    }

    public func didTerminateWebContentProcess(in webView: WKWebView) {
        viewModel?.webContentProcessDidTerminate()
    }

    public func startedDownload(for url: URL) {
        viewModel?.isDownloadsPresented = true
    }

    public func completedDownload(for url: URL) {
        viewModel?.isDownloadsPresented = true
    }
}

extension WKWebView {
    func createContext(contextId: JsContextIdentifier, deliveryQueue: JsEventDeliveryQueue) -> JsContext {
        return JsContext(id: contextId) { event in
            deliveryQueue.enqueue(event)
        }
    }

    /// Executes the polyfill's event dispatch inside the page.
    func sendTopazEvent(_ event: JsEvent, in world: WKContentWorld) async -> Result<Void, any Error> {
        return await withCheckedContinuation { continuation in
            callAsyncJavaScript(
                "topaz.sendEvent(event)",
                arguments: [ "event": event.jsValue ],
                in: nil,
                in: world) { result in
                    continuation.resume(returning: result.map { _ in () })
                }
        }
    }

    func detachScriptHandler(_ handler: ScriptHandler, in world: WKContentWorld) {
        handler.allHandlerNames.forEach { handlerName in
            configuration.userContentController.removeScriptMessageHandler(forName: handlerName, contentWorld: world)
        }
    }

    func attachScriptHandler(_ handler: ScriptHandler, in world: WKContentWorld) {
        handler.allHandlerNames.forEach { handlerName in
            configuration.userContentController.addScriptMessageHandler(handler, contentWorld: world, name: handlerName)
        }
    }
}

extension JsContextIdentifier {
    func withUrl(_ url: URL) -> Self {
        JsContextIdentifier(tab: tab, url: url)
    }
}
