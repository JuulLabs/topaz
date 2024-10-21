import Bluetooth
import CoreBluetooth

/**
 Marked as unchecked sendable so that we can hide the CBPeripheral reference inside AnyPeripheral.
 */
extension CBPeripheral: @retroactive @unchecked Sendable {}

/**
 TODO: To satisfy @unchecked Sendable we theoretically should lock-isolate all state when going
 through `PeripheralProtocol`. Accessing getters like name or state is probably fine for now.
 */
extension CBPeripheral: PeripheralProtocol {

    public var connectionState: Bluetooth.ConnectionState {
        switch self.state {
        case .disconnecting, .disconnected, .connecting:
            .disconnected
        case .connected:
            .connected
        @unknown default:
            .disconnected
        }
    }
}
