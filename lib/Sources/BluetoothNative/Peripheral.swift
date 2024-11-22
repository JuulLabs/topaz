import Bluetooth
import CoreBluetooth
import Helpers

extension CBPeripheral {
    func erase(locker: any LockingStrategy) -> Peripheral {
        Peripheral(
            peripheral: AnyProtectedObject(wrapping: self, in: locker),
            id: self.identifier,
            name: self.name
        )
    }
}

extension CBPeripheral: PeripheralProtocol {
    public var connectionState: ConnectionState {
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

extension Peripheral {
    var rawValue: CBPeripheral? {
        peripheral.wrapped.unsafeObject as? CBPeripheral
    }
}
