import Foundation

public struct CharacteristicDiscoveryFilter: Sendable {
    public let service: UUID
    public let characteristics: [UUID]?

    init(service: UUID, characteristics: [UUID]?) {
        self.service = service
        self.characteristics = characteristics
    }
}
