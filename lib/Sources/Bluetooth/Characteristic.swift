import Foundation
import Helpers

/**
 Shadows CBCharacteristic
 */
public struct Characteristic: Equatable, Sendable {
    public let characteristic: AnyProtectedObject
    public let uuid: UUID
    public let instance: UInt32
    public let properties: CharacteristicProperties
    public let value: Data?
    public let isNotifying: Bool
    public var descriptors: [Descriptor]

    public init(
        characteristic: AnyProtectedObject,
        uuid: UUID,
        instance: UInt32,
        properties: CharacteristicProperties,
        value: Data?,
        isNotifying: Bool,
        descriptors: [Descriptor] = []
    ) {
        self.characteristic = characteristic
        self.uuid = uuid
        self.instance = instance
        self.properties = properties
        self.value = value
        self.isNotifying = isNotifying
        self.descriptors = descriptors
    }
}
