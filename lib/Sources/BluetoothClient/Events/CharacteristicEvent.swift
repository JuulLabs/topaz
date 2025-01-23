import Bluetooth
import Foundation

public struct CharacteristicEvent: BluetoothEvent {
    public let name: EventName
    public let peripheralId: UUID
    public let characteristicId: UUID
    public let instance: UInt32

    public init(_ name: EventName, peripheralId: UUID, characteristicId: UUID, instance: UInt32) {
        self.name = name
        self.peripheralId = peripheralId
        self.characteristicId = characteristicId
        self.instance = instance
    }

    public var lookup: EventLookup {
        .exact(key: .characteristic(name, peripheralId: peripheralId, characteristicId: characteristicId, instance: instance))
    }
}

extension EventRegistrationKey {
    public static func characteristic(_ name: EventName, peripheralId: UUID, characteristicId: UUID, instance: UInt32) -> Self {
        EventRegistrationKey(
            name: name,
            peripheralId: peripheralId,
            // TODO: should we have serviceId here also?
            characteristicId: characteristicId,
            characteristicInstance: instance
        )
    }
}
