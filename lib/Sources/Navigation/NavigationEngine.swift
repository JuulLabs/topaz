import Foundation
import WebKit
import UIKit

@MainActor
public final class NavigationEngine: NSObject {
    private var recentDownloads: [URL] = []

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
        let document = errorDocument(for: error, url: item.request.url)
        if item.request.isNativelyRetryable {
            // Present the error content as the response for the original URL so the web view's current
            // history entry is that URL. Tapping reload then re-fetches the original page natively.
            webView.loadSimulatedRequest(URLRequest(url: item.request.url), responseHTML: document.render())
        } else {
            loadDocument(document, in: webView)
        }
    }

    func handleError(_ error: any Error, url: URL?, in webView: WKWebView) {
        guard shouldPresentErrorDocument(for: error) else { return }
        loadDocument(errorDocument(for: error, url: url), in: webView)
    }

    private func errorDocument(for error: any Error, url: URL?) -> SimpleHtmlDocument {
        if let rejectionStatusCode {
            statusCodeErrorDocument(statusCode: rejectionStatusCode, url: url, reason: rejectionReason)
        } else {
            genericErrorDocument(error: error, url: url, reason: rejectionReason)
        }
    }

    // We prefer using `load` via a data URI here as `loadHTMLString` bypasses navigation and so does not populate history
    private func loadDocument(_ document: SimpleHtmlDocument, in webView: WKWebView) {
        guard let request = document.asDataUriRequest() else {
            webView.loadHTMLString(document.render(), baseURL: nil)
            return
        }
        webView.load(request)
    }

    func rememberRecentDownload(_ url: URL) {
        recentDownloads.insert(url, at: 0)
        if recentDownloads.count > 5 {
            recentDownloads.removeLast(recentDownloads.count - 5)
        }
    }

    func isRecentDownload(_ url: URL) -> Bool {
        recentDownloads.contains(url)
    }

    func delegateURLToSystem(_ url: URL, onDenied: @escaping () -> Void = {}) {
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                onDenied()
            }
        }
    }
}
