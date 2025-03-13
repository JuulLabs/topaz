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

    var navigatingToUrl: URL?

    // Used for debug logging:
    var tab: Int {
        viewModel?.tab ?? -1
    }

    override init() {}


    func initialize(webView: WKWebView, model: WebPageModel) {
        self.viewModel = model
        self.messageProcessorFactory = model.messageProcessorFactory
        self.contextId = model.contextId

        self.navigationEngine = NavigationEngine(delegate: self)
        webView.customUserAgent = model.customUserAgent
        webView.navigationDelegate = navigationEngine
        webView.uiDelegate = navigationEngine

//        model.didInitializeWebView(webView)
    }

    func deinitialize(webView: WKWebView) {
        navigationEngine = nil
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
//        viewModel?.deinitialize(webView: webView)
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

    public func didInitiateNavigation(_ navigation: NavigationItem, in webView: WKWebView) {
        viewModel?.navigator.didInitiateNavigation(navigation, in: webView)
        //viewModel?.navigator.update(webView: webView, loadingState: navigation.observer.status)
        switch navigation.request.kind {
        case .newWindow:
            print("XXX didInitiateNavigation for new window")
            break
//            openLinkInNewTab(url: navigation.request.url)
        case .sameOrigin:
            print("XXX didInitiateNavigation for same origin")
            break
        case .crossOrigin:
            print("XXX didInitiateNavigation for cross origin - reboot context")
            detachOldHandler(from: webView)
            self.contextId = contextId.withUrl(navigation.request.url)
            attachNewHandler(to: webView)
        }
    }

    public func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView) {
        viewModel?.navigator.didBeginLoading(navigation, in: webView)
        viewModel?.didBeginLoading()
    }

    public func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView) {
        viewModel?.navigator.didEndLoading(navigation, in: webView)
    }

    public func openNewWindow(for url: URL) {
        viewModel?.navigator.openNewWindow(for: url)
    }

    public func didBeginNavigation(to url: URL, in webView: WKWebView) {
        detachOldHandler(from: webView)
        self.contextId = contextId.withUrl(url)
        attachNewHandler(to: webView)
    }

    public func didCommitNavigation(in webView: WKWebView) {
//        viewModel?.didCommitNavigation()
    }

    public func didFinishNavigation(to url: URL, in webView: WKWebView) {
    }

    public func redirectDueToError(to document: SimpleHtmlDocument) {
        navigatingToUrl = nil
//        viewModel?.navigator.redirect(to: document)
    }

    func openLinkInNewTab(url: URL?) {
        guard let launchNewPage = viewModel?.launchNewPage, let url else {
            return
        }
        navigatingToUrl = nil
        viewModel?.navigator.stopLoading()
        launchNewPage(url)
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
