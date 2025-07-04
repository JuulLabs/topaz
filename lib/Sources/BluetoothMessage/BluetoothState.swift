import Bluetooth
import Foundation
import Helpers
import OSLog
import SecurityList

private let log = Logger(subsystem: "BluetoothMessage", category: "BluetoothState")

/**
 Represents the current state of the bluetooth system.
 */
public actor BluetoothState {
    public private(set) var systemState: SystemState
    public private(set) var peripherals: [UUID: Peripheral]

    public let securityList: SecurityList

    private let store: CodableStorage?

    public init(
        systemState: SystemState = .unknown,
        peripherals: [Peripheral] = [],
        securityList: SecurityList = .init(),
        store: CodableStorage? = nil
    ) {
        self.systemState = systemState
        self.peripherals = peripherals.reduce(into: [UUID: Peripheral]()) { dictionary, peripheral in
            dictionary[peripheral.id] = peripheral
        }
        self.securityList = securityList
        self.store = store
    }

    public func setSystemState(_ systemState: SystemState) {
        self.systemState = systemState
    }

    public func removeAllPeripherals() -> [Peripheral] {
        let deadPeripherals = Array(peripherals.values)
        peripherals.removeAll()
        return deadPeripherals
    }

    public func putPeripheral(_ peripheral: Peripheral, replace: Bool) {
        guard replace || peripherals.index(forKey: peripheral.id) == nil else {
            return
        }
        self.peripherals[peripheral.id] = peripheral
    }

    public func getPeripheral(_ uuid: UUID) throws -> Peripheral {
        guard let peripheral = self.peripherals[uuid] else {
            throw BluetoothError.noSuchDevice(uuid)
        }
        return peripheral
    }

    public func rememberPeripheral(identifier uuid: UUID) async {
        var peripheralIds = await getKnownPeripheralIdentifiers()
        peripheralIds.insert(uuid)
        await save(peripheralIds: peripheralIds)
    }

    public func forgetPeripheral(identifier uuid: UUID) async {
        var peripheralIds = await getKnownPeripheralIdentifiers()
        peripheralIds.remove(uuid)
        await save(peripheralIds: peripheralIds)
    }

    public func forgetPeripherals(identifiers: [UUID]) async {
        var peripheralIds = await getKnownPeripheralIdentifiers()
        identifiers.forEach { peripheralIds.remove($0) }
        await save(peripheralIds: peripheralIds)
    }

    public func getKnownPeripheralIdentifiers() async -> Set<UUID> {
        (try? await store?.load(for: .uuidsKey)) ?? Set<UUID>()
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

    public func getCharacteristic(peripheralId uuid: UUID, serviceId: UUID, characteristicId: UUID, instance: UInt32) throws -> (Service, Characteristic) {
        let service = try getService(peripheralId: uuid, serviceId: serviceId)
        guard let characteristic = service.characteristics.first(where: { $0.uuid == characteristicId && $0.instance == instance }) else {
            throw BluetoothError.noSuchCharacteristic(service: serviceId, characteristic: characteristicId)
        }
        return (service, characteristic)
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

    public func setPermissions(_ permissions: PeripheralPermissions, on peripheralId: UUID) {
        self.peripherals[peripheralId]?.permissions = permissions
    }

    private func save(peripheralIds: Set<UUID>) async {
        guard let store else { return }
        do {
            try await store.save(peripheralIds, for: .uuidsKey)
        } catch {
            log.error("Unable to persist peripheralIds: \(error.localizedDescription)")
        }
    }
}

fileprivate extension String {
    static let uuidsKey = "savedPeripheralUUIDs"
}
