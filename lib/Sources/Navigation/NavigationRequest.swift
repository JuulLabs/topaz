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
    public let httpMethod: String?

    init(url: URL, kind: NavigationKind, actionType: WKNavigationType, isDownload: Bool, httpMethod: String?) {
        self.url = url
        self.kind = kind
        self.actionType = actionType
        self.isDownload = isDownload
        self.httpMethod = httpMethod
    }

    public init?(action: WKNavigationAction) {
        guard let url = action.request.url, url.isSchemeSupported else {
            return nil
        }
        self.url = url
        self.actionType = action.navigationType
        self.isDownload = action.shouldPerformDownload || url.hasDownloadScheme
        self.httpMethod = action.request.httpMethod
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
            return Self(url: url, kind: kind, actionType: actionType, isDownload: true, httpMethod: httpMethod)
        }
        return self
    }

    /// A request whose original URL can be safely re-fetched over the network on reload.
    /// Excludes downloads, non-GET methods (e.g. form POSTs we cannot replay), and
    /// non-network schemes (`about:`, `data:`, `blob:`). A nil method is treated as GET,
    /// matching HTTP/Foundation semantics, since WebKit often leaves it unset on plain navigations.
    var isNativelyRetryable: Bool {
        (httpMethod == nil || httpMethod == "GET") && !isDownload && url.hasHttpScheme
    }
}

private let downloadSchemes: Set<String> = ["blob"]
private let httpSchemes: Set<String> = ["https", "http"]
private let acceptedSchemes: Set<String> = downloadSchemes.union(httpSchemes).union(["about", "data"])

extension URL {
    var isWebNavigableScheme: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return acceptedSchemes.contains(scheme)
    }

    /// External schemes such as `mailto:` and `tel:` that should be handed off to the system.
    var shouldDelegateToSystem: Bool {
        scheme != nil && !isWebNavigableScheme
    }
}

private extension URL {
    var isSchemeSupported: Bool {
        isWebNavigableScheme
    }

    var hasDownloadScheme: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return downloadSchemes.contains(scheme)
    }

    var hasHttpScheme: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return httpSchemes.contains(scheme)
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
