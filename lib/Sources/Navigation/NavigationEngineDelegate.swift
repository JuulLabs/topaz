import Foundation
import WebKit

@MainActor
public protocol NavigationEngineDelegate: AnyObject {
    /// Called from the navigation policy decision before WebKit is allowed to begin the load.
    /// The navigation does not proceed until this returns, so the delegate may await work here.
    func prepareForNavigation(_ request: NavigationRequest, in webView: WKWebView) async
    /// The response converted an allowed navigation into a download, so the page that was
    /// already on screen stays there. Re-bind the context to that page.
    func restoreContextAfterDownload(in webView: WKWebView) async
    func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView)
    func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView)
    /// The system killed the web content process for this page, e.g. by jetsam. The Js
    /// heap and polyfill object graph are gone while native state, such as BLE
    /// connections, survives.
    func didTerminateWebContentProcess(in webView: WKWebView)
    func startedDownload(for url: URL)
    func completedDownload(for url: URL)
}
