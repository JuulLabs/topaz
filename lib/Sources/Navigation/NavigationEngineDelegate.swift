import Foundation
import WebKit

@MainActor
public protocol NavigationEngineDelegate: AnyObject {
    func didInitiateNavigation(_ navigation: NavigationItem, in webView: WKWebView)
    func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView)
    func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView)
    func openNewWindow(for url: URL)
}
