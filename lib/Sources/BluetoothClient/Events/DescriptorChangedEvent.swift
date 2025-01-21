import Bluetooth
import Foundation

public struct DescriptorChangedEvent: BluetoothEvent {
    public let name: EventName = .descriptorValue
    public let peripheralId: UUID
    public let characteristicId: UUID
    public let instance: UInt32
    public let descriptorId: UUID
    public let data: Data

    public init(peripheralId: UUID, characteristicId: UUID, instance: UInt32, descriptorId: UUID, data: Data) {
        self.peripheralId = peripheralId
        self.characteristicId = characteristicId
        self.instance = instance
        self.descriptorId = descriptorId
        self.data = data
    }

    public var lookup: EventLookup {
        .exact(
            key: .descriptor(
                name,
                peripheralId: peripheralId,
                characteristicId: characteristicId,
                instance: instance,
                descriptorId: descriptorId
            )
        )
    }
}
