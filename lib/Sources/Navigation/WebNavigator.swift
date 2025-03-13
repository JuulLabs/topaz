import Observation
import WebKit

@MainActor
@Observable
public final class WebNavigator {
    // Workaround dealloc() crash by never deallocing this thing:
    static private let placeholderBackForwardList = WKBackForwardList()

    @ObservationIgnored
    private weak var webView: WKWebView?

    @ObservationIgnored
    private weak var observer: WebViewObserver?

    public private(set) var backForwardList: WKBackForwardList = WebNavigator.placeholderBackForwardList
    public private(set) var canGoForward: Bool = false
    public private(set) var canGoBack: Bool = false

    private let initialLoadingState: WebPageLoadingState
    public var loadingState: WebPageLoadingState {
        observer.map { $0.status } ?? initialLoadingState
    }

    public var onPageLoaded: (URL, String?) -> Void = { _, _ in }

    public var launchNewPage: (URL) -> Void = { _ in }

    public init(loadingState: WebPageLoadingState = .initializing) {
        self.initialLoadingState = loadingState
    }

    public func goForward() {
        self.webView?.stopLoading()
        self.webView?.goForward()
    }

    public func goBack() {
        self.webView?.stopLoading()
        self.webView?.goBack()
    }

    public func reload() {
        self.webView?.reload()
    }

    public func stopLoading() {
        self.webView?.stopLoading()
    }

    public func go(to item: WKBackForwardListItem) {
        self.webView?.go(to: item)
    }

    func captureWebView(webView: WKWebView) {
        self.webView = webView
        self.backForwardList = webView.backForwardList
        self.canGoForward = webView.canGoForward
        self.canGoBack = webView.canGoBack
    }
}

extension WebNavigator: NavigationEngineDelegate {
    public func didInitiateNavigation(_ navigation: NavigationItem, in webView: WKWebView) {
        observer = navigation.observer
        captureWebView(webView: webView)
    }
    
    public func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView) {
        observer = navigation.observer
        captureWebView(webView: webView)
    }
    
    public func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView) {
        observer = navigation.observer
        captureWebView(webView: webView)
        onPageLoaded(navigation.request.url, webView.title)
    }

    public func openNewWindow(for url: URL) {
        stopLoading()
        launchNewPage(url)
    }
}
