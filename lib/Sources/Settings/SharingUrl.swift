import Foundation

public struct SharingUrl {
    public let url: URL
    public let subject: String?
    public let isDisabled: Bool

    public init(url: URL? = nil, subject: String? = nil) {
        self.url = url ?? URL(fileURLWithPath: "")
        self.subject = subject
        self.isDisabled = url == nil
    }
}
