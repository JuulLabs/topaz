import Bluetooth
import BluetoothClient
import CoreBluetooth
import Foundation

public func liveBluetoothClient() -> BluetoothClient {
    NativeBluetoothClient()
}

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

    func scan(options: Options?) -> any BluetoothScanner {
        return NativeScanner(options: options, coordinator: coordinator)
    }

    func enable() async {
        coordinator.enable()
    }

    func disable() async {
        coordinator.disable()
        await cancelPendingRequests()
    }

    public func prepareForShutdown(peripherals: [Peripheral]) async {
        for peripheral in peripherals {
            coordinator.disconnect(peripheral: peripheral)
        }
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

    func getPeripherals(withIdentifiers uuids: [UUID]) async -> [Peripheral] {
        await coordinator.retrievePeripherals(withIdentifiers: uuids)
    }

    func connect(_ peripheral: Peripheral) async throws -> PeripheralEvent {
        try await server.awaitEvent(key: .peripheral(.connect, peripheral)) {
            coordinator.connect(peripheral: peripheral)
        }
    }

    func disconnect(_ peripheral: Peripheral) async throws -> DisconnectionEvent {
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

    func discoverDescriptors(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> DescriptorDiscoveryEvent {
        try await server.awaitEvent(key: .descriptorDiscovery(peripheralId: peripheral.id, characteristicId: characteristic.uuid, instance: characteristic.instance)) {
            coordinator.discoverDescriptors(peripheral: peripheral, characteristic: characteristic)
        }
    }

    func characteristicSetNotifications(_ peripheral: Peripheral, service: Service, characteristic: Characteristic, enable: Bool) async throws -> CharacteristicEvent {
        try await server.awaitEvent(
            key: .characteristic(
                .characteristicNotify,
                peripheralId: peripheral.id,
                serviceId: service.uuid,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance
            )
        ) {
            coordinator.setNotify(peripheral: peripheral, characteristic: characteristic, value: enable)
        }
    }

    func characteristicWrite(_ peripheral: Peripheral, service: Service, characteristic: Characteristic, value: Data, withResponse: Bool) async throws -> CharacteristicEvent {
        guard withResponse else {
            coordinator.writeCharacteristic(peripheral: peripheral, characteristic: characteristic, value: value, withResponse: withResponse)
            return CharacteristicEvent(
                .characteristicWrite,
                peripheralId: peripheral.id,
                serviceId: service.uuid,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance
            )
        }
        return try await server.awaitEvent(
            key: .characteristic(
                .characteristicWrite,
                peripheralId: peripheral.id,
                serviceId: service.uuid,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance
            )
        ) {
            coordinator.writeCharacteristic(peripheral: peripheral, characteristic: characteristic, value: value, withResponse: withResponse)
        }
    }

    func characteristicRead(_ peripheral: Peripheral, service: Service, characteristic: Characteristic) async throws -> CharacteristicChangedEvent {
        return try await server.awaitEvent(
            key: .characteristic(
                .characteristicValue,
                peripheralId: peripheral.id,
                serviceId: service.uuid,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance
            )
        ) {
            coordinator.readCharacteristic(peripheral: peripheral, characteristic: characteristic)
        }
    }

    func descriptorRead(_ peripheral: Peripheral, characteristic: Characteristic, descriptor: Descriptor) async throws -> DescriptorChangedEvent {
        return try await server.awaitEvent(key: .descriptor(.descriptorValue, peripheralId: peripheral.id, characteristicId: characteristic.uuid, instance: characteristic.instance, descriptorId: descriptor.uuid)) {
            coordinator.readDescriptor(peripheral: peripheral, descriptor: descriptor)
        }
    }
}
