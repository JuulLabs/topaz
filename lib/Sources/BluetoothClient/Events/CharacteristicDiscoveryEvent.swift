import Bluetooth
import Foundation

public struct CharacteristicDiscoveryEvent: BluetoothEvent {
    public let name: EventName = .discoverCharacteristics
    public let peripheralId: UUID
    public let serviceId: UUID
    public let characteristics: [Characteristic]

    public init(peripheralId: UUID, serviceId: UUID, characteristics: [Characteristic]) {
        self.peripheralId = peripheralId
        self.serviceId = serviceId
        self.characteristics = characteristics
    }

    public var key: EventKey {
        .characteristicDiscovery(peripheralId: peripheralId, serviceId: serviceId)
    }
}

extension EventKey {
    public static func characteristicDiscovery(peripheralId: UUID, serviceId: UUID) -> Self {
        EventKey(name: .discoverCharacteristics, peripheralId, serviceId)
    }
}
