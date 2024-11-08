import Foundation

/**
 Shadows CBCharacteristic
 */
public struct Characteristic: Equatable, Sendable {
    public let uuid: UUID
    public let instance: UInt32
    public let properties: CharacteristicProperties
    public let value: Data?
    public let descriptors: [Descriptor]
    public let isNotifying: Bool

    public init(
        uuid: UUID,
        instance: UInt32,
        properties: CharacteristicProperties,
        value: Data?,
        descriptors: [Descriptor],
        isNotifying: Bool
    ) {
        self.uuid = uuid
        self.instance = instance
        self.properties = properties
        self.value = value
        self.descriptors = descriptors
        self.isNotifying = isNotifying
    }
}
