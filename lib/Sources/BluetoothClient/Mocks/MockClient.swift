import Bluetooth
import Foundation

public struct MockBluetoothClient: BluetoothClient {

    public let events: AsyncStream<any BluetoothEvent>
    public let eventsContinuation: AsyncStream<any BluetoothEvent>.Continuation

    public var onEnable: @Sendable () async -> Void
    public var onDisable: @Sendable () async -> Void
    public var onPrepareForShutdown: @Sendable ([Peripheral]) async -> Void
    public var onResolvePendingRequests: @Sendable  (BluetoothEvent) async -> Void
    public var onCancelPendingRequests: @Sendable () async -> Void
    public var onScan: @Sendable (_ options: Options?) async -> BluetoothScanner
    public var onSystemState: @Sendable () async throws -> SystemStateEvent
    public var onGetPeripherals: @Sendable (_ uuids: [UUID]) async -> [Peripheral]
    public var onConnect: @Sendable (_ peripheral: Peripheral) async throws -> PeripheralEvent
    public var onDisconnect: @Sendable (_ peripheral: Peripheral) async throws -> DisconnectionEvent
    public var onDiscoverServices: @Sendable (_ peripheral: Peripheral, _ filter: ServiceDiscoveryFilter) async throws -> ServiceDiscoveryEvent
    public var onDiscoverCharacteristics: @Sendable (_ peripheral: Peripheral, _ filter: CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent
    public var onDiscoverDescriptors: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic) async throws -> DescriptorDiscoveryEvent
    public var onCharacteristicSetNotifications: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ enabled: Bool) async throws -> CharacteristicEvent
    public var onCharacteristicRead: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic) async throws -> CharacteristicChangedEvent
    public var onCharacteristicWrite: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ value: Data, _ withResponse: Bool) async throws -> CharacteristicEvent
    public var onDescriptorRead: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ descriptor: Descriptor) async throws -> DescriptorChangedEvent

    public init() {
        let (stream, continuation) = AsyncStream<any BluetoothEvent>.makeStream()
        self.events = stream
        self.eventsContinuation = continuation
        self.onEnable = { fatalError("Not implemented") }
        self.onDisable = { fatalError("Not implemented") }
        self.onPrepareForShutdown = { _ in fatalError("Not implemented") }
        self.onResolvePendingRequests = { _ in fatalError("Not implemented") }
        self.onCancelPendingRequests = { fatalError("Not implemented") }
        self.onScan = { _ in fatalError("Not implemented") }
        self.onSystemState = { fatalError("Not implemented") }
        self.onGetPeripherals = { _ in fatalError("Not implemented") }
        self.onConnect = { _ in fatalError("Not implemented") }
        self.onDisconnect = { _ in fatalError("Not implemented") }
        self.onDiscoverServices = { _, _ in fatalError("Not implemented") }
        self.onDiscoverCharacteristics = { _, _ in fatalError("Not implemented") }
        self.onDiscoverDescriptors = { _, _ in fatalError("Not implemented") }
        self.onCharacteristicSetNotifications = { _, _, _ in fatalError("Not implemented") }
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

    public func prepareForShutdown(peripherals: [Peripheral]) async {
        await onPrepareForShutdown(peripherals)
    }

    public func resolvePendingRequests(for event: BluetoothEvent) async {
        await onResolvePendingRequests(event)
    }

    public func cancelPendingRequests() async {
        await onCancelPendingRequests()
    }

    public func scan(options: Options?) async -> any BluetoothScanner {
        await onScan(options)
    }

    public func systemState() async throws -> SystemStateEvent {
        try await onSystemState()
    }

    public func getPeripherals(withIdentifiers uuids: [UUID]) async -> [Peripheral] {
        await onGetPeripherals(uuids)
    }

    public func connect(_ peripheral: Peripheral) async throws -> PeripheralEvent {
        try await onConnect(peripheral)
    }

    public func disconnect(_ peripheral: Peripheral) async throws -> DisconnectionEvent {
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

    public func characteristicSetNotifications(_ peripheral: Peripheral, service: Service, characteristic: Characteristic, enable: Bool) async throws -> CharacteristicEvent {
        try await onCharacteristicSetNotifications(peripheral, characteristic, enable)
    }

    public func characteristicRead(_ peripheral: Peripheral, service: Service, characteristic: Characteristic) async throws -> CharacteristicChangedEvent {
        try await onCharacteristicRead(peripheral, characteristic)
    }

    public func characteristicWrite(_ peripheral: Peripheral, service: Service, characteristic: Characteristic, value: Data, withResponse: Bool) async throws -> CharacteristicEvent {
        try await onCharacteristicWrite(peripheral, characteristic, value, withResponse)
    }

    public func descriptorRead(_ peripheral: Peripheral, characteristic: Characteristic, descriptor: Descriptor) async throws -> DescriptorChangedEvent {
        try await onDescriptorRead(peripheral, characteristic, descriptor)
    }
}
