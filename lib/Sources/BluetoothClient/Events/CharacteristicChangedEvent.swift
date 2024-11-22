import Bluetooth
import Foundation

public struct CharacteristicChangedEvent: BluetoothEvent {
    public let name: EventName = .characteristicValue
    public let peripheralId: UUID
    public let characteristicId: UUID
    public let instance: UInt32
    public let data: Data?

    public init(peripheralId: UUID, characteristicId: UUID, instance: UInt32, data: Data?) {
        self.peripheralId = peripheralId
        self.characteristicId = characteristicId
        self.instance = instance
        self.data = data
    }

    public var key: EventKey {
        .characteristic(name, peripheralId: peripheralId, characteristicId: characteristicId, instance: instance)
    }
}
