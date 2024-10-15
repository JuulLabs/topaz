import Foundation

public struct Filter: Sendable {
    public let services: [UUID]
    // TODO: filter options

    init(services: [UUID]) {
        self.services = services
    }
}
