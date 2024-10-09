import Foundation
import WebKit

@MainActor
public class Coordinator: NSObject {
    private let parent: WebPageView

    let messageNames: [String] = []

    init(_ parent: WebPageView) {
        self.parent = parent
    }

    func initialize(webView: WKWebView, model: WebPageModel) {
        webView.customUserAgent = model.customUserAgent
        webView.navigationDelegate = self
        messageNames.forEach { name in
            webView.configuration.userContentController
                .addScriptMessageHandler(self, contentWorld: .page, name: name)
        }
        // TODO: inject scripts here
    }

    func update(webView: WKWebView, model: WebPageModel) {
        // TODO: load when observed model url changes only
        webView.load(URLRequest(url: model.url))
    }
}
