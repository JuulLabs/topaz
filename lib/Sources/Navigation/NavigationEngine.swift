import Foundation
import WebKit

@MainActor
public final class NavigationEngine: NSObject {
    var latestRequest: NavigationRequest?
    var navigations: [WKNavigation: NavigationItem] = [:]

    var rejectionReason: String?
    var rejectionStatusCode: Int?

    var navigator: WebNavigator

    public weak var delegate: NavigationEngineDelegate?

    public init(navigator: WebNavigator) {
        self.navigator = navigator
    }

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
