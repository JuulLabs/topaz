import Bluetooth
import Foundation

public actor BluetoothState: Sendable {
    private var peripherals: [UUID: AnyPeripheral]

    public init(
        peripherals: [AnyPeripheral] = []
    ) {
        self.peripherals = peripherals.reduce(into: [UUID: AnyPeripheral]()) { dictionary, peripheral in
            dictionary[peripheral.identifier] = peripheral
        }
    }

    func putPeripheral(_ peripheral: AnyPeripheral) {
        peripherals[peripheral.identifier] = peripheral
    }

    func getPeripheral(_ uuid: UUID) throws -> AnyPeripheral {
        guard let peripheral = peripherals[uuid] else {
            throw BluetoothError.noSuchDevice(uuid)
        }
        return peripheral
    }
}
