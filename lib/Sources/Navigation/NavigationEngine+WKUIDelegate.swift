import Foundation
import OSLog
import WebKit

private let log = Logger(subsystem: "WebView", category: "UIDelegate")

extension NavigationEngine: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            log.warning("NavigationAction request url is nil")
            return nil
        }

        guard let request = NavigationRequest(action: navigationAction) else {
            delegateURLToSystem(url)
            return nil
        }

        guard request.kind == .newWindow else {
            log.warning("Request for new window ignored action=\(navigationAction)")
            return nil
        }

        log.debug("Request opens in new window action=\(navigationAction)")
        latestRequest = nil
        navigator.stopLoadingAndOpenNewWindow(url: request.url)
        return nil
    }
}
