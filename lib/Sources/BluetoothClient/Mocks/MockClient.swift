import Bluetooth
import Foundation

public struct MockBluetoothClient: BluetoothClient {
    public let events: AsyncStream<any BluetoothEvent>
    public let eventsContinuation: AsyncStream<any BluetoothEvent>.Continuation

    public var onEnable: @Sendable () async -> Void
    public var onDisable: @Sendable () async -> Void
    public var onResolvePendingRequests: @Sendable  (BluetoothEvent) async -> Void
    public var onCancelPendingRequests: @Sendable () async -> Void
    public var onScan: @Sendable (_ filter: Filter) async -> BluetoothScanner
    public var onSystemState: @Sendable () async throws -> SystemStateEvent
    public var onConnect: @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEvent
    public var onDisconnect: @Sendable (_ peripheral: AnyPeripheral) async throws -> PeripheralEvent
    public var onDiscoverServices: @Sendable (_ peripheral: AnyPeripheral, _ filter: ServiceDiscoveryFilter) async throws -> PeripheralEvent
    public var onDiscoverCharacteristics: @Sendable (_ peripheral: AnyPeripheral, _ filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEvent
    public var onCharacteristicNotify: @Sendable (_ peripheral: AnyPeripheral, _ characteristic: Characteristic, _ enabled: Bool) async throws -> CharacteristicEvent
    public var onCharacteristicRead: @Sendable (_ peripheral: AnyPeripheral, _ serviceUuid: UUID, _ characteristicUuid: UUID, _ instance: UInt32) async throws -> CharacteristicEvent

    public init() {
        let (stream, continuation) = AsyncStream<any BluetoothEvent>.makeStream()
        self.events = stream
        self.eventsContinuation = continuation
        self.onEnable = { fatalError("Not implemented") }
        self.onDisable = { fatalError("Not implemented") }
        self.onResolvePendingRequests = { _ in fatalError("Not implemented") }
        self.onCancelPendingRequests = { fatalError("Not implemented") }
        self.onScan = { _ in fatalError("Not implemented") }
        self.onSystemState = { fatalError("Not implemented") }
        self.onConnect = { _ in fatalError("Not implemented") }
        self.onDisconnect = { _ in fatalError("Not implemented") }
        self.onDiscoverServices = { _, _ in fatalError("Not implemented") }
        self.onDiscoverCharacteristics = { _, _ in fatalError("Not implemented") }
        self.onCharacteristicNotify = { _, _, _ in fatalError("Not implemented") }
        self.onCharacteristicRead = { _, _, _, _ in fatalError("Not implemented") }
    }

    public func enable() async {
        await onEnable()
    }

    public func disable() async {
        await onDisable()
    }

    public func resolvePendingRequests(for event: BluetoothEvent) async {
        await onResolvePendingRequests(event)
    }

    public func cancelPendingRequests() async {
        await onCancelPendingRequests()
    }

    public func scan(filter: Bluetooth.Filter) async -> any BluetoothScanner {
        await onScan(filter)
    }

    public func systemState() async throws -> SystemStateEvent {
        try await onSystemState()
    }

    public func connect(_ peripheral: Bluetooth.AnyPeripheral) async throws -> PeripheralEvent {
        try await onConnect(peripheral)
    }

    public func disconnect(_ peripheral: Bluetooth.AnyPeripheral) async throws -> PeripheralEvent {
        try await onDisconnect(peripheral)
    }

    public func discoverServices(_ peripheral: Bluetooth.AnyPeripheral, filter: Bluetooth.ServiceDiscoveryFilter) async throws -> PeripheralEvent {
        try await onDiscoverServices(peripheral, filter)
    }

    public func discoverCharacteristics(_ peripheral: Bluetooth.AnyPeripheral, filter: Bluetooth.CharacteristicDiscoveryFilter) async throws -> PeripheralEvent {
        try await onDiscoverCharacteristics(peripheral, filter)
    }

    public func characteristicNotify(_ peripheral: Bluetooth.AnyPeripheral, _ characteristic: Bluetooth.Characteristic, enabled: Bool) async throws -> CharacteristicEvent {
        try await onCharacteristicNotify(peripheral, characteristic, enabled)
    }

    public func characteristicRead(_ peripheral: Bluetooth.AnyPeripheral, serviceUuid: UUID, characteristicUuid: UUID, instance: UInt32) async throws -> CharacteristicEvent {
        try await onCharacteristicRead(peripheral, serviceUuid, characteristicUuid, instance)
    }
}
