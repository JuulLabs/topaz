import Bluetooth
import Foundation

public struct ServiceDiscoveryEvent: BluetoothEvent {
    public let name: EventName = .discoverServices
    public let peripheralId: UUID
    public let services: [Service]

    public init(peripheralId: UUID, services: [Service]) {
        self.peripheralId = peripheralId
        self.services = services
    }

    public var key: EventKey {
        .serviceDiscovery(peripheralId: peripheralId)
    }
}

extension EventKey {
    public static func serviceDiscovery(peripheralId: UUID) -> Self {
        EventKey(name: .discoverServices, peripheralId)
    }
}
