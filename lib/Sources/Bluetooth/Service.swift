import Foundation

/**
 Shadows CBService
 */
public struct Service: Equatable, Sendable {
    public let uuid: UUID
    public let isPrimary: Bool
    public let characteristics: [Characteristic]

    public init(uuid: UUID, isPrimary: Bool, characteristics: [Characteristic] = []) {
        self.uuid = uuid
        self.isPrimary = isPrimary
        self.characteristics = characteristics
    }
}
