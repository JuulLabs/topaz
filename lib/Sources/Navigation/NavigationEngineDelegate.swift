import Foundation
import WebKit

@MainActor
public protocol NavigationEngineDelegate: AnyObject {
    func prepareContext(for request: NavigationRequest, in webView: WKWebView) async
    func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView)
    func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView)
    func startedDownload(for url: URL)
    func completedDownload(for url: URL)
}
