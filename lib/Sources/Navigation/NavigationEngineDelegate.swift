import Foundation
import WebKit

@MainActor
public protocol NavigationEngineDelegate: AnyObject {
    func didInitiateNavigation(_ navigation: NavigationItem, in webView: WKWebView)
    func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView)
    func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView)
    /// The system killed the page's web content process (e.g. jetsam): its Js heap and
    /// polyfill object graph are gone while native state (BLE connections) survives.
    func didTerminateWebContentProcess(in webView: WKWebView)
    func startedDownload(for url: URL)
    func completedDownload(for url: URL)
}
