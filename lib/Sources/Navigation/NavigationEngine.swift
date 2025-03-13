import Foundation
import OSLog
import WebKit

private let log = Logger(subsystem: "WebView", category: "NavigationDelegate")


@MainActor
public final class NavigationEngine: NSObject {
    var latestRequest: NavigationRequest?
    var navigations: [WKNavigation: NavigationItem] = [:]

    var rejectionReason: String?
    var rejectionStatusCode: Int?

    public weak var delegate: NavigationEngineDelegate?

    public init(delegate: NavigationEngineDelegate? = nil) {
        self.delegate = delegate
    }

//    let navigator: WebNavigator
//    public init(delo: NavDel, navigator: WebNavigator) {
//        self.delo = delo
//        self.navigator = navigator
//    }

    // TODO: set this to be the thing we want the web view to load?
    // But only if it isn't a back/forward type thing can we ignore those?
    var urlToLoad: URL?

    // Also, use KVO to monitor the webview url property as it changes as we navigate

    func handleError(_ error: any Error, for navigation: WKNavigation, in webView: WKWebView) {
        guard shouldPresentErrorDocument(for: error) else { return }
        guard let item = navigations.removeValue(forKey: navigation) else { return }
        let document = if let rejectionStatusCode {
            statusCodeErrorDocument(statusCode: rejectionStatusCode, url: item.request.url, reason: rejectionReason)
        } else {
            genericErrorDocument(error: error, url: item.request.url, reason: rejectionReason)
        }
        loadDocument(document, in: webView)
    }

    // We prefer using `load` via a data URI here as `loadHTMLString` bypasses navigation and so does not populate history
    private func loadDocument(_ document: SimpleHtmlDocument, in webView: WKWebView) {
        guard let request = document.asDataUriRequest() else {
            webView.loadHTMLString(document.render(), baseURL: nil)
            return
        }
        webView.load(request)
    }
}
