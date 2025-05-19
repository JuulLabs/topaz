import Foundation

public struct EventAttributes: Sendable, Hashable {
    public var peripheralId: UUID?
    public var serviceId: UUID?
    public var characteristicId: UUID?
    public var characteristicInstance: UInt32?
    public var descriptorId: UUID?

    public init(
        peripheralId: UUID? = nil,
        serviceId: UUID? = nil,
        characteristicId: UUID? = nil,
        characteristicInstance: UInt32? = nil,
        descriptorId: UUID? = nil
    ) {
        self.peripheralId = peripheralId
        self.serviceId = serviceId
        self.characteristicId = characteristicId
        self.characteristicInstance = characteristicInstance
        self.descriptorId = descriptorId
    }
}
