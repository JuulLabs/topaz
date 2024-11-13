import Bluetooth
import Foundation

protocol Effector: Sendable {
    @discardableResult
    func getSystemState(predicate: (@Sendable (SystemState) throws -> Bool)?) async throws -> SystemStateEffect

    @discardableResult
    func getAdvertisement() async throws -> AdvertisementEffect

    @discardableResult
    func connect(peripheral: AnyPeripheral) async throws -> PeripheralEffect

    @discardableResult
    func disconnect(peripheral: AnyPeripheral) async throws -> PeripheralEffect

    @discardableResult
    func discoverServices(peripheral: AnyPeripheral, filter: ServiceDiscoveryFilter) async throws -> PeripheralEffect

    @discardableResult
    func discoverCharacteristics(peripheral: AnyPeripheral, filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEffect

    @discardableResult
    func characteristicNotify(peripheral: AnyPeripheral, characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEffect

    @discardableResult
    func characteristicRead(peripheral: AnyPeripheral, characteristic: Characteristic) async throws -> CharacteristicEffect
}

extension Effector {
    /// Blocks until we are in powered on state
    /// Throws an error if the state is not powered on
    func bluetoothReadyState() async throws {
        try await getSystemState() { state in
            switch state {
            case .poweredOn:
                true
            case .unsupported, .unauthorized, .poweredOff:
                throw BluetoothError.unavailable
            case .unknown, .resetting:
                // Keep waiting - the system emits unknown until it has finished starting up
                false
            }
        }
    }
}
