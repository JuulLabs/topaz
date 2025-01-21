import Bluetooth
import Foundation

public struct CharacteristicDiscoveryEvent: BluetoothEvent {
    public let peripheralId: UUID
    public let serviceId: UUID
    public let characteristics: [Characteristic]

    public init(peripheralId: UUID, serviceId: UUID, characteristics: [Characteristic]) {
        self.peripheralId = peripheralId
        self.serviceId = serviceId
        self.characteristics = characteristics
    }

    public var lookup: EventLookup {
        .exact(key: .characteristicDiscovery(peripheralId: peripheralId, serviceId: serviceId))
    }
}

extension EventRegistrationKey {
    public static func characteristicDiscovery(peripheralId: UUID, serviceId: UUID) -> Self {
        EventRegistrationKey(name: .discoverCharacteristics, peripheralId: peripheralId, serviceId: serviceId)
    }
}
