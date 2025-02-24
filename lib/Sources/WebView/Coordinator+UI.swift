import Foundation
import OSLog
import WebKit

private let log = Logger(subsystem: "WebView", category: "WKUIDelegate")

extension Coordinator: WKUIDelegate {

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        log.debug("createWebView navigationAction=\(navigationAction) \(self.extraDebugInfo)")
        openLinkInNewTab(url: navigationAction.request.url)
        return nil
    }

}
