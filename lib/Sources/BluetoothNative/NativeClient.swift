import Bluetooth
import BluetoothClient
import CoreBluetooth
import Foundation

public let liveBluetoothClient: BluetoothClient = NativeBluetoothClient()

// add stat stop funcs here
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

    func connect(_ peripheral: Peripheral) async throws -> PeripheralEvent {
        try await server.awaitEvent(key: .peripheral(.connect, peripheral)) {
            coordinator.connect(peripheral: peripheral)
        }
    }

    func disconnect(_ peripheral: Peripheral) async throws -> PeripheralEvent {
        try await server.awaitEvent(key: .peripheral(.disconnect, peripheral)) {
            coordinator.disconnect(peripheral: peripheral)
        }
    }

    func discoverServices(_ peripheral: Peripheral, filter: ServiceDiscoveryFilter) async throws -> ServiceDiscoveryEvent {
        try await server.awaitEvent(key: .serviceDiscovery(peripheralId: peripheral.id)) {
            coordinator.discoverServices(peripheral: peripheral, uuids: filter.services)
        }
    }

    func discoverCharacteristics(_ peripheral: Peripheral, filter: CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent {
        guard let service = peripheral.services.first(where: { $0.uuid == filter.service }) else {
            throw BluetoothError.noSuchService(filter.service)
        }
        return try await server.awaitEvent(key: .characteristicDiscovery(peripheralId: peripheral.id, serviceId: service.uuid)) {
            coordinator.discoverCharacteristics(peripheral: peripheral, service: service, uuids: filter.characteristics)
        }
    }

    func characteristicNotify(_ peripheral: Peripheral, _ characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEvent {
        try await server.awaitEvent(key: .characteristic(.characteristicNotify, peripheralId: peripheral.id, characteristicId: characteristic.uuid, instance: characteristic.instance)) {
            // TODO:
        }
    }

    func characteristicRead(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicChangedEvent {
        return try await server.awaitEvent(key: .characteristic(.characteristicValue, peripheralId: peripheral.id, characteristicId: characteristic.uuid, instance: characteristic.instance)) {
            coordinator.readCharacteristic(peripheral: peripheral, characteristic: characteristic)
        }
    }

    func startNotify(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicEvent {
        try await server.awaitEvent(key: .characteristic(.start, peripheralId: peripheral.id, characteristicId: characteristic.uuid, instance: characteristic.instance)) {
            coordinator.startNotify(peripheral: peripheral, characteristic: characteristic)
        }
    }
}
