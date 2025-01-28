import Observation
import WebKit

@MainActor
@Observable
public final class WebNavigator {
    // Workaround dealloc() crash by never deallocing this thing:
    static private let placeholderBackForwardList = WKBackForwardList()

    @ObservationIgnored
    private weak var webView: WKWebView?

    public private(set) var backForwardList: WKBackForwardList = WebNavigator.placeholderBackForwardList
    public private(set) var canGoForward: Bool = false
    public private(set) var canGoBack: Bool = false

    public private(set) var loadingState: WebPageLoadingState = .initializing {
        willSet {
            if case .complete = newValue, let url = webView?.url {
                onPageLoaded(url, webView?.title)
            }
        }
    }

    public var onPageLoaded: (URL, String?) -> Void = { _, _ in }

    public init(loadingState: WebPageLoadingState = .initializing) {
        self.loadingState = loadingState
    }

    public func goForward() {
        self.webView?.goForward()
    }

    public func goBack() {
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

    func update(webView: WKWebView) {
        self.webView = webView
        self.backForwardList = webView.backForwardList
        self.canGoForward = webView.canGoForward
        self.canGoBack = webView.canGoBack
    }

    func updateLoadingState(isLoading: Bool) async {
        if isLoading {
            // We are usually already in progress by the time isLoading flips to true
            guard case .inProgress = loadingState else {
                loadingState = .inProgress(0.0)
                return
            }
        } else {
            if loadingState.isProgressIncomplete {
                // Smooth out the transition to 100% with a small delay
                loadingState = .inProgress(1.0)
                try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 15)
                // Double check state didn't change while we slept
                if loadingState.isProgressComplete {
                    loadingState = .complete
                }
            } else {
                loadingState = .complete
            }
        }
    }

    func updateLoadingProgress(progress: Float) async {
        loadingState = .inProgress(progress)
    }
}
