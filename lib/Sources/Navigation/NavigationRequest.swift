import Foundation
import WebKit

/**
 Created when we decide policy for a navigation action.
 Applies the logic to figure out the nature of a navigation action.
 */
@MainActor
public struct NavigationRequest {
    public let url: URL
    public let kind: NavigationKind
    public let actionType: WKNavigationType
    public let isDownload: Bool

    init(url: URL, kind: NavigationKind, actionType: WKNavigationType, isDownload: Bool) {
        self.url = url
        self.kind = kind
        self.actionType = actionType
        self.isDownload = isDownload
    }

    public init?(action: WKNavigationAction) {
        guard let url = action.request.url, url.isSchemeSupported else {
            return nil
        }
        self.url = url
        self.actionType = action.navigationType
        self.isDownload = action.shouldPerformDownload || url.hasDownloadScheme
        guard let targetFrame = action.targetFrame else {
            // WARNING: non-nullable navigationAction.sourceFrame property may actually be nil http://www.openradar.appspot.com/FB9877215
            let sourceFrame: WKFrameInfo? = action.sourceFrame
            guard let sourceFrame, sourceFrame.isMainFrame else {
                // Here we deny opening a new window unless requested from the main frame
                return nil
            }
            self.kind = .newWindow
            return
        }
        guard let host = url.host(percentEncoded: false), host == targetFrame.securityOrigin.host else {
            self.kind = .crossOrigin
            return
        }
        self.kind = .sameOrigin
    }

    func matchesResponse(navigationResponse: WKNavigationResponse) -> Bool {
        url == navigationResponse.response.url
    }

    func updated(with navigationResponse: WKNavigationResponse) -> Self {
        if !isDownload && navigationResponse.shouldDownload() {
            return Self(url: url, kind: kind, actionType: actionType, isDownload: true)
        }
        return self
    }
}

private let downloadSchemes: Set<String> = ["blob"]
private let acceptedSchemes: Set<String> = downloadSchemes.union(["about", "https", "http", "data"])

private extension URL {
    var isSchemeSupported: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return acceptedSchemes.contains(scheme)
    }

    var hasDownloadScheme: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return downloadSchemes.contains(scheme)
    }
}

private extension WKNavigationResponse {
    func httpHeader(_ key: String) -> String? {
        (response as? HTTPURLResponse)?.value(forHTTPHeaderField: key)
    }

    func shouldDownload() -> Bool {
        !canShowMIMEType || httpHeader("Content-Disposition")?.lowercased().contains("attachment") == true
    }
}
