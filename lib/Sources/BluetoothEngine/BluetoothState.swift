import Bluetooth
import Foundation

public actor BluetoothState: Sendable {
    private(set) var peripherals: [UUID: AnyPeripheral]
    private(set) var systemState: SystemState

    public init(
        systemState: SystemState = .unknown,
        peripherals: [AnyPeripheral] = []
    ) {
        self.systemState = systemState
        self.peripherals = peripherals.reduce(into: [UUID: AnyPeripheral]()) { dictionary, peripheral in
            dictionary[peripheral.identifier] = peripheral
        }
    }

    func setSystemState(_ systemState: SystemState) {
        self.systemState = systemState
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
