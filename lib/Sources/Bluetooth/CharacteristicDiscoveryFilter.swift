import Foundation

public struct CharacteristicDiscoveryFilter: Sendable {
    public let characteristics: [UUID]?

    public init(characteristics: [UUID]?) {
        self.characteristics = characteristics
    }
}
