import Bluetooth
import Foundation

public struct CharacteristicChangedEvent: BluetoothEvent {
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

    public var lookup: EventLookup {
        .exact(key: .characteristic(.characteristicValue, peripheralId: peripheralId, characteristicId: characteristicId, instance: instance))
    }
}
