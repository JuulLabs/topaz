import Foundation

public struct ServiceDiscoveryFilter: Sendable {
    public let primaryOnly: Bool
    public let services: [UUID]?

    init(primaryOnly: Bool, services: [UUID]?) {
        self.primaryOnly = primaryOnly
        self.services = services
    }
}
