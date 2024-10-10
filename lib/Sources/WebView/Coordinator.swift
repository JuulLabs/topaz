import Foundation
import WebKit

@MainActor
public class Coordinator: NSObject {
    let handlers: [ScriptHandler] = []

    override init() {}

    func initialize(webView: WKWebView, model: WebPageModel) {
        webView.customUserAgent = model.customUserAgent
        webView.navigationDelegate = self
        handlers.forEach { handler in
            webView.configuration.userContentController.addScriptMessageHandler(handler, contentWorld: .page, name: handler.name)
        }
        // TODO: inject scripts here
    }

    func deinitialize(webView: WKWebView) {
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.configuration.userContentController.removeAllUserScripts()
    }
    
    func update(webView: WKWebView, model: WebPageModel) {
        // TODO: load when observed model url changes only
        webView.load(URLRequest(url: model.url))
    }
}
