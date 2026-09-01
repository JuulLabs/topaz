import Foundation
import WebKit

@MainActor
public protocol NavigationEngineDelegate: AnyObject {
    func didInitiateNavigation(_ navigation: NavigationItem, in webView: WKWebView)
    func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView)
    func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView)
    /// The system killed the web content process for this page, e.g. by jetsam. The Js
    /// heap and polyfill object graph are gone while native state, such as BLE
    /// connections, survives.
    func didTerminateWebContentProcess(in webView: WKWebView)
    func startedDownload(for url: URL)
    func completedDownload(for url: URL)
}
