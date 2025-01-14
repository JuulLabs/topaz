import Bluetooth
import Foundation

public struct DescriptorEvent: BluetoothEvent {
    public let name: EventName
    public let peripheralId: UUID
    public let characteristicId: UUID
    public let instance: UInt32
    public let descriptorId: UUID

    public init(_ name: EventName, peripheralId: UUID, characteristicId: UUID, instance: UInt32, descriptorId: UUID) {
        self.name = name
        self.peripheralId = peripheralId
        self.characteristicId = characteristicId
        self.instance = instance
        self.descriptorId = descriptorId
    }

    public var key: EventKey {
        .descriptor(name, peripheralId: peripheralId, characteristicId: characteristicId, instance: instance, descriptorId: descriptorId)
    }
}

extension EventKey {
    public static func descriptor(_ name: EventName, peripheralId: UUID, characteristicId: UUID, instance: UInt32, descriptorId: UUID) -> Self {
        EventKey(name: name, peripheralId, characteristicId, instance, descriptorId)
    }
}
