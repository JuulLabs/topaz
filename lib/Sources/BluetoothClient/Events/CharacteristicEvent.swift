import Bluetooth
import Foundation

// can be used for start/stop
public struct CharacteristicEvent: BluetoothEvent {
    public let name: EventName // add to eventName
    public let peripheralId: UUID
    public let characteristicId: UUID
    public let instance: UInt32

    public init(_ name: EventName, peripheralId: UUID, characteristicId: UUID, instance: UInt32) {
        self.name = name
        self.peripheralId = peripheralId
        self.characteristicId = characteristicId
        self.instance = instance
    }

    public var key: EventKey {
        .characteristic(name, peripheralId: peripheralId, characteristicId: characteristicId, instance: instance)
    }
}

extension EventKey {
    public static func characteristic(_ name: EventName, peripheralId: UUID, characteristicId: UUID, instance: UInt32) -> Self {
        EventKey(name: name, peripheralId, characteristicId, instance)
    }
}
