import Foundation

public struct CharacteristicDiscoveryFilter: Sendable {
    public let service: UUID
    public let characteristics: [UUID]?

    public init(service: UUID, characteristics: [UUID]?) {
        self.service = service
        self.characteristics = characteristics
    }
}
