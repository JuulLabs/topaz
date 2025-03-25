import Foundation
import WebKit

public struct NavigationItem: Sendable {
    public let navigation: WKNavigation
    public let request: NavigationRequest
}
