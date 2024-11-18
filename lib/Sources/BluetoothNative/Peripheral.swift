import Bluetooth
import CoreBluetooth

/**
 Marked as unchecked sendable so that we can hide the CBPeripheral reference inside AnyPeripheral.
 */
extension CBPeripheral: @retroactive @unchecked Sendable {}

/**
 TODO: To satisfy @unchecked Sendable we theoretically should lock-isolate all state when going
 through `PeripheralProtocol`. Accessing getters like name or state is probably fine for now.
 In practice the only valid choice would be to access on the bluetooth dispatch queue only. :(
 */
extension CBPeripheral: WrappedPeripheral {
    public var _identifier: UUID {
        self.identifier
    }

    public var _connectionState: ConnectionState {
        switch self.state {
        case .disconnecting, .disconnected, .connecting:
            .disconnected
        case .connected:
            .connected
        @unknown default:
            .disconnected
        }
    }

    public var _name: String? {
        self.name
    }

    public var _services: [Bluetooth.Service] {
        return services?.compactMap { $0.toService() } ?? []
    }
}
