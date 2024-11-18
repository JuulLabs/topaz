import Bluetooth
import Foundation

/**
 Represents the current state of the bluetooth system.
 */
public actor BluetoothState: Sendable {
    private(set) var peripherals: [UUID: AnyPeripheral]
    public private(set) var systemState: SystemState

    public init(
        systemState: SystemState = .unknown,
        peripherals: [AnyPeripheral] = []
    ) {
        self.systemState = systemState
        self.peripherals = peripherals.reduce(into: [UUID: AnyPeripheral]()) { dictionary, peripheral in
            dictionary[peripheral.identifier] = peripheral
        }
    }

    public func setSystemState(_ systemState: SystemState) {
        self.systemState = systemState
    }

    public func putPeripheral(_ peripheral: AnyPeripheral) {
        peripherals[peripheral.identifier] = peripheral
    }

    public func getPeripheral(_ uuid: UUID) throws -> AnyPeripheral {
        guard let peripheral = peripherals[uuid] else {
            throw BluetoothError.noSuchDevice(uuid)
        }
        return peripheral
    }
}
