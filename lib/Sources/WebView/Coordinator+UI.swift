import Foundation
import WebKit

extension Coordinator: WKUIDelegate {

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            print("TODO: open \(url) in a new tab")
        }
        navigatingToUrl = nil
        return nil
    }
}
