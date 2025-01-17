import Bluetooth
import Foundation

/**
 Represents the current state of the bluetooth system.
 */
public actor BluetoothState: Sendable {

    public let (stateStream, continuation) = AsyncStream<SystemState>.makeStream()

    public private(set) var systemState: SystemState {
        didSet {
            continuation.yield(systemState)
        }
    }

    private(set) var peripherals: [UUID: Peripheral]

    public init(
        systemState: SystemState = .unknown,
        peripherals: [Peripheral] = []
    ) {
        self.systemState = systemState
        self.peripherals = peripherals.reduce(into: [UUID: Peripheral]()) { dictionary, peripheral in
            dictionary[peripheral.id] = peripheral
        }
    }

    public func setSystemState(_ systemState: SystemState) {
        self.systemState = systemState
    }

    public func setCanSendWriteWithoutResponse(_ peripheralId: UUID, value: Bool) async {
        await self.peripherals[peripheralId]?.canSendWriteWithoutResponse.setValue(value)
    }

    public func getCanSendWriteWithoutResponse(_ peripheral: Peripheral) async throws -> Bool {
        try await getPeripheral(peripheral.id).canSendWriteWithoutResponse.getValue() ?? false
    }

    public func putPeripheral(_ peripheral: Peripheral) {
        self.peripherals[peripheral.id] = peripheral
    }

    public func getPeripheral(_ uuid: UUID) throws -> Peripheral {
        guard let peripheral = self.peripherals[uuid] else {
            throw BluetoothError.noSuchDevice(uuid)
        }
        return peripheral
    }

    public func getService(peripheralId uuid: UUID, serviceId: UUID) throws -> Service {
        guard let service = try getPeripheral(uuid).services.first(where: { $0.uuid == serviceId }) else {
            throw BluetoothError.noSuchService(serviceId)
        }
        return service
    }

    public func getServices(peripheralId uuid: UUID) throws -> [Service] {
        try getPeripheral(uuid).services
    }

    public func setServices(_ services: [Service], on peripheralId: UUID) {
        self.peripherals[peripheralId]?.services = services
    }

    public func getCharacteristic(peripheralId uuid: UUID, serviceId: UUID, characteristicId: UUID, instance: UInt32) throws -> Characteristic {
        let service = try getService(peripheralId: uuid, serviceId: serviceId)
        guard let characteristic = service.characteristics.first(where: { $0.uuid == characteristicId && $0.instance == instance }) else {
            throw BluetoothError.noSuchCharacteristic(service: serviceId, characteristic: characteristicId)
        }
        return characteristic
    }

    public func getCharacteristics(peripheralId uuid: UUID, serviceId: UUID) throws -> [Characteristic] {
        try getService(peripheralId: uuid, serviceId: serviceId).characteristics
    }

    public func setCharacteristics(_ characteristics: [Characteristic], on peripheralId: UUID, serviceId: UUID) {
        guard let index = self.peripherals[peripheralId]?.services.firstIndex(where: { $0.uuid == serviceId }) else {
            return
        }
        self.peripherals[peripheralId]?.services[index].characteristics = characteristics
    }

    public func setDescriptors(_ descriptors: [Descriptor], on peripheralId: UUID, serviceId: UUID, characteristicId: UUID, instance: UInt32) {
        guard let serviceIndex = self.peripherals[peripheralId]?.services.firstIndex(where: { $0.uuid == serviceId }) else {
            return
        }
        guard let characteristicIndex = self.peripherals[peripheralId]?.services[serviceIndex].characteristics.firstIndex(where: { $0.uuid == characteristicId && $0.instance == instance }) else {
            return
        }
        self.peripherals[peripheralId]?.services[serviceIndex].characteristics[characteristicIndex].descriptors = descriptors
    }
}
