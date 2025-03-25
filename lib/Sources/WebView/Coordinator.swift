import BluetoothClient
import Foundation
import JsMessage
import Navigation
import WebKit

@MainActor
public class Coordinator: NSObject, NavigationEngineDelegate {
    private let world: WKContentWorld = .page
    private var messageProcessorFactory: JsMessageProcessorFactory!
    private var contextId: JsContextIdentifier!
    private var scriptHandler: ScriptHandler?
    private var viewModel: WebPageModel?
    private var navigationEngine: NavigationEngine?

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
    }

    func deinitialize(webView: WKWebView) {
        navigationEngine = nil
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        viewModel = nil
        detachOldHandler(from: webView)
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.configuration.userContentController.removeAllUserScripts()
    }

    func update(webView: WKWebView, model: WebPageModel) {
        // TODO: load when observed model url changes only
        webView.load(URLRequest(url: model.url))
    }

    private func attachNewHandler(to webView: WKWebView) {
        let context = webView.createContext(contextId: contextId, world: world)
        let newHandler = ScriptHandler(context: context, factory: messageProcessorFactory)
        self.scriptHandler = newHandler
        webView.attachScriptHandler(newHandler, in: world)
    }

    private func detachOldHandler(from webView: WKWebView) {
        guard let scriptHandler else { return }
        scriptHandler.detachProcessors()
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
            // Tear down and spin up a new Js context for this new web page
            detachOldHandler(from: webView)
            self.contextId = contextId.withUrl(navigation.request.url)
            attachNewHandler(to: webView)
        }
    }

    public func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView) {
        viewModel?.didBeginLoading()
    }

    public func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView) {
    }
}

extension WKWebView {
    func createContext(contextId: JsContextIdentifier, world: WKContentWorld) -> JsContext {
        return JsContext(id: contextId) { [weak self] event in
            return await withCheckedContinuation { continuation in
                self?.callAsyncJavaScript(
                    "topaz.sendEvent(event)",
                    arguments: [ "event": event.jsValue ],
                    in: nil,
                    in: world) { result in
                        continuation.resume(returning: result.map { _ in () })
                    }
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
