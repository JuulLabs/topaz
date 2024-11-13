import Bluetooth
import Foundation

public struct Effector: Sendable {
    public var systemState: @Sendable (_ predicate: (@Sendable (SystemState) throws -> Bool)?) async throws -> SystemStateEffect
    public var advertisement: @Sendable () async throws -> AdvertisementEffect
    public var connect: @Sendable (AnyPeripheral) async throws -> PeripheralEffect
    public var disconnect: @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEffect
    public var discoverServices: @Sendable (_ peripheral: AnyPeripheral, _ filter: ServiceDiscoveryFilter) async throws -> PeripheralEffect
    public var discoverCharacteristics: @Sendable (_ peripheral: AnyPeripheral,_ filter:  CharacteristicDiscoveryFilter) async throws -> PeripheralEffect
    public var characteristicNotify: @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic, _ enabled: Bool) async throws -> CharacteristicEffect
    public var characteristicRead: @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic) async throws -> CharacteristicEffect

    public init(
        systemState: @escaping @Sendable (_ predicate: (@Sendable (SystemState) throws -> Bool)?) async throws -> SystemStateEffect,
        advertisement: @escaping @Sendable () async throws -> AdvertisementEffect,
        connect: @escaping @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEffect,
        disconnect: @escaping @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEffect,
        discoverServices: @escaping @Sendable (_ peripheral: AnyPeripheral, _ filter: ServiceDiscoveryFilter) async throws -> PeripheralEffect,
        discoverCharacteristics: @escaping @Sendable (_ peripheral: AnyPeripheral,_ filter:  CharacteristicDiscoveryFilter) async throws -> PeripheralEffect,
        characteristicNotify: @escaping @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic, _ enabled: Bool) async throws -> CharacteristicEffect,
        characteristicRead: @escaping @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic) async throws -> CharacteristicEffect
    ) {
        self.systemState = systemState
        self.advertisement = advertisement
        self.connect = connect
        self.disconnect = disconnect
        self.discoverServices = discoverServices
        self.discoverCharacteristics = discoverCharacteristics
        self.characteristicNotify = characteristicNotify
        self.characteristicRead = characteristicRead
    }
}

extension Effector {
    public static let testValue = Effector(
        systemState: { _ in fatalError("Not implemented") },
        advertisement: { fatalError("Not implemented") },
        connect: { _ in fatalError("Not implemented") },
        disconnect: { _ in fatalError("Not implemented") },
        discoverServices: { _, _ in fatalError("Not implemented") },
        discoverCharacteristics: { _, _ in fatalError("Not implemented") },
        characteristicNotify: { _, _, _ in fatalError("Not implemented") },
        characteristicRead: { _, _ in fatalError("Not implemented") }
    )
}

protocol EffectorProtocol: Sendable {
    @discardableResult
    func systemState(predicate: (@Sendable (SystemState) throws -> Bool)?) async throws -> SystemStateEffect

    @discardableResult
    func advertisement() async throws -> AdvertisementEffect

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
        try await systemState { state in
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
