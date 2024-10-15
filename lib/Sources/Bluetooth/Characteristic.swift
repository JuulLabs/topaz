import Foundation

/**
 Shadows CBCharacteristic
 */
public struct Characteristic: Equatable, Sendable {
    public let uuid: UUID
    public let properties: CharacteristicProperties
    public let value: Data?
    public let descriptors: [Descriptor]
    public let isNotifying: Bool
}
