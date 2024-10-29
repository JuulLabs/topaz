import Foundation

/// Identifies the unique instance of an open web page tab
public struct JsContextIdentifier: Sendable, Hashable {
    public let tab: Int
    public let url: URL

    public init(tab: Int, url: URL) {
        self.tab = tab
        self.url = url
    }
}
