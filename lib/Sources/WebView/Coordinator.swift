import BluetoothClient
import Foundation
import JsMessage
import WebKit

@MainActor
public class Coordinator: NSObject {
    private let world: WKContentWorld = .page
    private var messageProcessorFactory: JsMessageProcessorFactory!
    private var contextId: JsContextIdentifier!
    private var scriptHandler: ScriptHandler?
    private var viewModel: WebPageModel?

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

        webView.customUserAgent = model.customUserAgent
        webView.navigationDelegate = self
        webView.uiDelegate = self

        model.didInitializeWebView(webView)
    }

    func deinitialize(webView: WKWebView) {
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        viewModel?.deinitialize(webView: webView)
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

    func didBeginNavigation(to url: URL, in webView: WKWebView) {
        viewModel?.navigator.update(webView: webView)
        detachOldHandler(from: webView)
        self.contextId = contextId.withUrl(url)
        attachNewHandler(to: webView)
        // TODO: tell model url changed without reloading it
    }

    func didCommitNavigation(in webView: WKWebView) {
        viewModel?.navigator.update(webView: webView)
        viewModel?.didCommitNavigation()
    }

    func didFinishNavigation(to url: URL, in webView: WKWebView) {
        viewModel?.navigator.update(webView: webView)
    }

    func redirectDueToError(to document: SimpleHtmlDocument) {
        navigatingToUrl = nil
        viewModel?.navigator.redirect(to: document)
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
#if DEBUG
            print("EVENT: \(event.jsValue)")
#endif
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
