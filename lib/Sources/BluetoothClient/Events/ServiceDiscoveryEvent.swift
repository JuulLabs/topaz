import Bluetooth
import Foundation

public struct ServiceDiscoveryEvent: BluetoothEvent {
    public let peripheralId: UUID
    public let services: [Service]

    public init(peripheralId: UUID, services: [Service]) {
        self.peripheralId = peripheralId
        self.services = services
    }

    public var lookup: EventLookup {
        .exact(key: .serviceDiscovery(peripheralId: peripheralId))
    }
}

extension EventRegistrationKey {
    public static func serviceDiscovery(peripheralId: UUID) -> Self {
        EventRegistrationKey(name: .discoverServices, peripheralId: peripheralId)
    }
}
