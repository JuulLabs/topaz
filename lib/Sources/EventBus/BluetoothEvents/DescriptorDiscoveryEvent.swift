import Bluetooth
import Foundation

public struct DescriptorDiscoveryEvent: BluetoothEvent {
    public let peripheralId: UUID
    public let serviceId: UUID
    public let characteristicId: UUID
    public let instance: UInt32
    public let descriptors: [Descriptor]

    public init(peripheralId: UUID, serviceId: UUID, characteristicId: UUID, instance: UInt32, descriptors: [Descriptor]) {
        self.peripheralId = peripheralId
        self.serviceId = serviceId
        self.characteristicId = characteristicId
        self.instance = instance
        self.descriptors = descriptors
    }

    public var lookup: EventLookup {
        .exact(key: .descriptorDiscovery(peripheralId: peripheralId, characteristicId: characteristicId, instance: instance))
    }
}

extension EventRegistrationKey {
    public static func descriptorDiscovery(peripheralId: UUID, characteristicId: UUID, instance: UInt32) -> Self {
        EventRegistrationKey(
            name: .discoverDescriptors,
            peripheralId: peripheralId,
            // TODO: service id?
            characteristicId: characteristicId,
            characteristicInstance: instance
        )
    }
}
