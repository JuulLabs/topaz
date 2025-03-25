import Foundation
import WebKit

/**
 Created when we decide policy for a navigation action.
 Applies the logic to figure out the nature of a navigation action.
 */
@MainActor
public struct NavigationRequest: Sendable {
    public let url: URL
    public let kind: NavigationKind
    public let actionType: WKNavigationType

    init(url: URL, kind: NavigationKind, actionType: WKNavigationType) {
        self.url = url
        self.kind = kind
        self.actionType = actionType
    }

    public init?(action: WKNavigationAction) {
        guard let url = action.request.url, url.isSchemeSupported else {
            return nil
        }
        self.url = url
        self.actionType = action.navigationType
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
}

private let acceptedSchemes: Set<String> = ["about", "https", "http", "data"]

extension URL {
    var isSchemeSupported: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return acceptedSchemes.contains(scheme)
    }
}
