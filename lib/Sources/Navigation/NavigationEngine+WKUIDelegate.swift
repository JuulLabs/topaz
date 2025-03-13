import Foundation
import OSLog
import WebKit

private let log = Logger(subsystem: "WebView", category: "UIDelegate")

extension NavigationEngine: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let request = NavigationRequest(action: navigationAction), request.kind == .newWindow {
            log.debug("Request opens in new window action=\(navigationAction)")
            latestRequest = nil
            delegate?.openNewWindow(for: request.url)
        } else {
            log.warning("Request for new window ignored action=\(navigationAction)")
        }
        return nil
    }
}
