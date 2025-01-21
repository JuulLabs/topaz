import Bluetooth
import BluetoothMessage
import Foundation

extension BluetoothState {
    func getConnectedPeripheral(_ uuid: UUID) throws -> Peripheral {
        let peripheral = try getPeripheral(uuid)
        guard peripheral.connectionState == .connected else {
            throw BluetoothError.deviceNotConnected
        }
        return peripheral
    }
}
