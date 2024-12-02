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

    public init() {
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
}
