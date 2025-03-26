import Bluetooth
import Foundation

public struct CharacteristicEvent: BluetoothEvent {
    public let name: EventName
    public let peripheralId: UUID
    public let serviceId: UUID
    public let characteristicId: UUID
    public let instance: UInt32

    public init(_ name: EventName, peripheralId: UUID, serviceId: UUID, characteristicId: UUID, instance: UInt32) {
        self.name = name
        self.peripheralId = peripheralId
        self.serviceId = serviceId
        self.characteristicId = characteristicId
        self.instance = instance
    }

    public var lookup: EventLookup {
        .exact(key: .characteristic(name, peripheralId: peripheralId, serviceId: serviceId, characteristicId: characteristicId, instance: instance))
    }
}

extension EventRegistrationKey {
    public static func characteristic(_ name: EventName, peripheralId: UUID, serviceId: UUID, characteristicId: UUID, instance: UInt32) -> Self {
        EventRegistrationKey(
            name: name,
            peripheralId: peripheralId,
            serviceId: serviceId,
            characteristicId: characteristicId,
            characteristicInstance: instance
        )
    }
}
