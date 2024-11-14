import Bluetooth
import BluetoothClient
import Foundation

public struct Effector: Sendable, DelegateEventProcessor {
    public var onDelegateEvent: @Sendable (_ event: DelegateEvent) async -> Void
    public var onCancelEvents: @Sendable (_ error: any Error) async -> Void
    public var systemState: @Sendable (_ predicate: (@Sendable (SystemState) throws -> Bool)?) async throws -> SystemStateEffect
    public var advertisement: @Sendable () async throws -> AdvertisementEffect
    public var connect: @Sendable (AnyPeripheral) async throws -> PeripheralEffect
    public var disconnect: @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEffect
    public var discoverServices: @Sendable (_ peripheral: AnyPeripheral, _ filter: ServiceDiscoveryFilter) async throws -> PeripheralEffect
    public var discoverCharacteristics: @Sendable (_ peripheral: AnyPeripheral, _ filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEffect
    public var characteristicNotify: @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic, _ enabled: Bool) async throws -> CharacteristicEffect
    public var characteristicRead: @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic) async throws -> CharacteristicEffect

    public init(
        onDelegateEvent: @escaping @Sendable (_ event: DelegateEvent) async -> Void,
        onCancelEvents: @escaping @Sendable (_ error: any Error) async -> Void,
        systemState: @escaping @Sendable (_ predicate: (@Sendable (SystemState) throws -> Bool)?) async throws -> SystemStateEffect,
        advertisement: @escaping @Sendable () async throws -> AdvertisementEffect,
        connect: @escaping @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEffect,
        disconnect: @escaping @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEffect,
        discoverServices: @escaping @Sendable (_ peripheral: AnyPeripheral, _ filter: ServiceDiscoveryFilter) async throws -> PeripheralEffect,
        discoverCharacteristics: @escaping @Sendable (_ peripheral: AnyPeripheral, _ filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEffect,
        characteristicNotify: @escaping @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic, _ enabled: Bool) async throws -> CharacteristicEffect,
        characteristicRead: @escaping @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic) async throws -> CharacteristicEffect
    ) {
        self.onDelegateEvent = onDelegateEvent
        self.onCancelEvents = onCancelEvents
        self.systemState = systemState
        self.advertisement = advertisement
        self.connect = connect
        self.disconnect = disconnect
        self.discoverServices = discoverServices
        self.discoverCharacteristics = discoverCharacteristics
        self.characteristicNotify = characteristicNotify
        self.characteristicRead = characteristicRead
    }

    public func ingestDelegateEvent(_ event: DelegateEvent) async {
        await onDelegateEvent(event)
    }

    public func cancelAllEvents(with error: any Error) async {
        await onCancelEvents(error)
    }
}

extension Effector {
    public static let testValue = Effector(
        onDelegateEvent: { _ in fatalError("Not implemented") },
        onCancelEvents: { _ in fatalError("Not implemented") },
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
