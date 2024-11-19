import Bluetooth
import BluetoothClient
import CoreBluetooth
import Foundation

public let liveBluetoothClient: BluetoothClient = NativeBluetoothClient()


struct NativeBluetoothClient: BluetoothClient {
    private let coordinator: Coordinator
    private let server: EventService

    var events: AsyncStream<any BluetoothEvent> {
        coordinator.events
    }

    init() {
        self.coordinator = Coordinator()
        self.server = EventService()
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

    func resolvePendingRequests(for event: any BluetoothEvent) async {
        await server.handleEvent(event)
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

    func characteristicRead(_ peripheral: Bluetooth.AnyPeripheral, serviceUuid: UUID, characteristicUuid: UUID, instance: UInt32) async throws -> CharacteristicEvent {
        // TODO: tidy up the key handling on this
        let key = EventKey(name: .characteristicValue, peripheral.identifier, characteristicUuid, instance)
        return try await server.awaitEvent(key: key) {
            coordinator.readCharacteristic(peripheral: peripheral, service: serviceUuid, characteristic: characteristicUuid, instance: instance)
        }
    }
}
