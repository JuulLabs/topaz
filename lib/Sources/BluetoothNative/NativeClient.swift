import Bluetooth
import BluetoothClient
import CoreBluetooth
import Foundation

public let liveBluetoothClient: BluetoothClient = NativeBluetoothClient()


struct NativeBluetoothClient: BluetoothClient {
    private let coordinator: Coordinator
    private let server: EventService
    private let eventsContinuation: AsyncStream<any BluetoothEvent>.Continuation

    let events: AsyncStream<any BluetoothEvent>

    init() {
        let eventService = EventService()
        self.coordinator = Coordinator()
        self.server = eventService
        let (stream, continuation) = AsyncStream<any BluetoothEvent>.makeStream()
        self.events = stream
        self.eventsContinuation = continuation
        Task { [events = coordinator.events, server] in
            for await event in events {
                continuation.yield(event)
                await server.handleEvent(event)
            }
        }
    }

    private func handleEvent(_ event: BluetoothEvent) async {
        eventsContinuation.yield(event)
        await server.handleEvent(event)
    }

    func scan(filter: Filter) -> any BluetoothScanner {
        return NativeScanner(filter: filter, coordinator: coordinator)
    }

    func enable() async {
        coordinator.enable()
    }

    func disable() async {
        coordinator.disable()
        await cancelPendingRequests()
    }

    func cancelPendingRequests() async {
        await server.cancelAllEvents(with: BluetoothError.cancelled)
    }

    func systemState() async throws -> SystemStateEvent {
        try await server.awaitEvent(key: .systemState) {
        }
    }

    func connect(_ peripheral: AnyPeripheral) async throws -> PeripheralEvent {
        try await server.awaitEvent(key: .peripheral(.connect, peripheral)) {
            coordinator.connect(peripheral: peripheral)
        }
    }

    func disconnect(_ peripheral: AnyPeripheral) async throws -> PeripheralEvent {
        try await server.awaitEvent(key: .peripheral(.disconnect, peripheral)) {
            coordinator.disconnect(peripheral: peripheral)
        }
    }

    func discoverServices(_ peripheral: AnyPeripheral, filter: ServiceDiscoveryFilter) async throws -> PeripheralEvent {
        try await server.awaitEvent(key: .peripheral(.discoverServices, peripheral)) {
            coordinator.discoverServices(peripheral: peripheral, filter: filter)
        }
    }

    func discoverCharacteristics(_ peripheral: AnyPeripheral, filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEvent {
        try await server.awaitEvent(key: .peripheral(.discoverCharacteristics, peripheral)) {
            coordinator.discoverCharacteristics(peripheral: peripheral, filter: filter)
        }
    }

    func characteristicNotify(_ peripheral: AnyPeripheral, _ characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEvent {
        try await server.awaitEvent(key: .characteristic(.characteristicValue, peripheral, characteristic)) {
            // TODO:
        }
    }

    func characteristicRead(_ peripheral: AnyPeripheral, _ characteristic: Characteristic) async throws -> CharacteristicEvent {
        try await server.awaitEvent(key: .characteristic(.characteristicNotify, peripheral, characteristic)) {
            // TODO:
        }
    }
}
