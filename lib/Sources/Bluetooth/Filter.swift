import Foundation

public struct Filter: Sendable {
    public let services: [UUID]

    // TODO: filter options
    public var options: [String: Any]? {
        nil
    }

    public init(services: [UUID]) {
        self.services = services
    }
}
