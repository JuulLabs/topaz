import Foundation

/**
 The identification key associated with an event when it is registered.
 */
public struct EventRegistrationKey: Sendable, Hashable {
    public let name: EventName
    public let attributes: EventAttributes

    public init(name: EventName, attributes: EventAttributes) {
        self.name = name
        self.attributes = attributes
    }

    public init(
        name: EventName,
        peripheralId: UUID? = nil,
        serviceId: UUID? = nil,
        characteristicId: UUID? = nil,
        characteristicInstance: UInt32? = nil,
        descriptorId: UUID? = nil
    ) {
        let attributes = EventAttributes(
            peripheralId: peripheralId,
            serviceId: serviceId,
            characteristicId: characteristicId,
            characteristicInstance: characteristicInstance,
            descriptorId: descriptorId
        )
        self.init(name: name, attributes: attributes)
    }
}
