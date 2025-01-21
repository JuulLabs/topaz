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
    public var onConnect: @Sendable (_ peripheral: Peripheral) async throws -> PeripheralEvent
    public var onDisconnect: @Sendable (_ peripheral: Peripheral) async throws -> PeripheralEvent
    public var onDiscoverServices: @Sendable (_ peripheral: Peripheral, _ filter: ServiceDiscoveryFilter) async throws -> ServiceDiscoveryEvent
    public var onDiscoverCharacteristics: @Sendable (_ peripheral: Peripheral, _ filter: CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent
    public var onDiscoverDescriptors: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic) async throws -> DescriptorDiscoveryEvent
    public var onCharacteristicNotify: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ enabled: Bool) async throws -> CharacteristicEvent
    public var onCharacteristicRead: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic) async throws -> CharacteristicChangedEvent
    public var onCharacteristicWrite: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ value: Data, _ withResponse: Bool) async throws -> CharacteristicEvent
    public var onDescriptorRead: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ descriptor: Descriptor) async throws -> DescriptorChangedEvent

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
        self.onDiscoverDescriptors = { _, _ in fatalError("Not implemented") }
        self.onCharacteristicNotify = { _, _, _ in fatalError("Not implemented") }
        self.onCharacteristicRead = { _, _ in fatalError("Not implemented") }
        self.onCharacteristicWrite = { _, _, _, _ in fatalError("Not implemented") }
        self.onDescriptorRead = { _, _, _ in fatalError("Not implemented") }
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

    public func scan(filter: Filter) async -> any BluetoothScanner {
        await onScan(filter)
    }

    public func systemState() async throws -> SystemStateEvent {
        try await onSystemState()
    }

    public func connect(_ peripheral: Peripheral) async throws -> PeripheralEvent {
        try await onConnect(peripheral)
    }

    public func disconnect(_ peripheral: Peripheral) async throws -> PeripheralEvent {
        try await onDisconnect(peripheral)
    }

    public func discoverServices(_ peripheral: Peripheral, filter: Bluetooth.ServiceDiscoveryFilter) async throws -> ServiceDiscoveryEvent {
        try await onDiscoverServices(peripheral, filter)
    }

    public func discoverCharacteristics(_ peripheral: Peripheral, filter: Bluetooth.CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent {
        try await onDiscoverCharacteristics(peripheral, filter)
    }

    public func discoverDescriptors(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> DescriptorDiscoveryEvent {
        try await onDiscoverDescriptors(peripheral, characteristic)
    }

    public func characteristicNotify(_ peripheral: Peripheral, characteristic: Bluetooth.Characteristic, enabled: Bool) async throws -> CharacteristicEvent {
        try await onCharacteristicNotify(peripheral, characteristic, enabled)
    }

    public func characteristicRead(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicChangedEvent {
        try await onCharacteristicRead(peripheral, characteristic)
    }

    public func characteristicWrite(_ peripheral: Peripheral, characteristic: Characteristic, value: Data, withResponse: Bool) async throws -> CharacteristicEvent {
        try await onCharacteristicWrite(peripheral, characteristic, value, withResponse)
    }

    public func descriptorRead(_ peripheral: Peripheral, characteristic: Characteristic, descriptor: Descriptor) async throws -> DescriptorChangedEvent {
        try await onDescriptorRead(peripheral, characteristic, descriptor)
    }
}
