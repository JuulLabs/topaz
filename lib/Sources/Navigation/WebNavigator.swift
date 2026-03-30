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
    private var loadingObserver: LoadingStateObserver?

    @ObservationIgnored
    private var navigationStateObserver: NavigationStateObserver?

    public private(set) var backForwardList: WKBackForwardList = WebNavigator.placeholderBackForwardList
    public private(set) var canGoForward: Bool = false
    public private(set) var canGoBack: Bool = false
    public var isInSearchMode: Bool = true

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
        webView?.stopLoading()
        webView?.goForward()
    }

    public func goBack() {
        webView?.stopLoading()
        webView?.goBack()
    }

    public func reload() {
        webView?.reload()
    }

    public func stopLoading() {
        webView?.stopLoading()
    }

    public func go(to item: WKBackForwardListItem) {
        webView?.go(to: item)
    }

    private func update(webView: WKWebView) {
        self.webView = webView
        backForwardList = webView.backForwardList
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    public func startObservingNavigationState(of webView: WKWebView) {
        update(webView: webView)
        navigationStateObserver = NavigationStateObserver(webView: webView)
        navigationStateObserver?.onNavigationStateChange = { [weak self] webView in
            self?.update(webView: webView)
        }
    }

    public func stopObservingNavigationState() {
        navigationStateObserver = nil
    }

    func startObservingLoadingProgress(of webView: WKWebView) {
        loadingObserver = LoadingStateObserver(webView: webView)
        loadingObserver?.onLoadingStateChange = { [weak self] webView, newState in
            guard let self else { return }
            self.loadingState = newState
            if case let .complete(url) = newState {
                self.onPageLoaded(url, webView.title)
                self.loadingObserver = nil
            }
        }
    }

    func stopLoadingAndOpenNewWindow(url: URL) {
        loadingObserver = nil
        stopLoading()
        launchNewPage(url)
    }
}
