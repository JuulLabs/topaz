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
    var observer: WebViewObserver?

    public private(set) var backForwardList: WKBackForwardList = WebNavigator.placeholderBackForwardList
    public private(set) var canGoForward: Bool = false
    public private(set) var canGoBack: Bool = false

    public private(set) var loadingState: WebPageLoadingState {
        willSet {
            if case let .complete(url) = newValue {
                onPageLoaded(url, webView?.title)
            }
        }
    }

    @ObservationIgnored
    public var onPageLoaded: (URL, String?) -> Void = { _, _ in }

    @ObservationIgnored
    public var launchNewPage: (URL) -> Void = { _ in }

    public init(loadingState: WebPageLoadingState = .initializing) {
        self.loadingState = loadingState
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

    private func update(webView: WKWebView) {
        self.webView = webView
        self.backForwardList = webView.backForwardList
        self.canGoForward = webView.canGoForward
        self.canGoBack = webView.canGoBack
    }

    func startObservingLoadingProgress(of webView: WKWebView) {
        self.observer = WebViewObserver(webView: webView)
        self.observer?.onLoadingStateChange = { [weak self] webView, newState in
            guard let self else { return }
            self.loadingState = newState
            self.update(webView: webView)
        }
    }

    func stopObservingLoadingProgress(of webView: WKWebView) {
        if let url = webView.url {
            self.onPageLoaded(url, webView.title)
        }
        self.observer = nil
    }

    func stopLoadingAndOpenNewWindow(url: URL) {
        self.observer = nil
        self.stopLoading()
        self.launchNewPage(url)
    }
}
