import Bluetooth
import CoreBluetooth

class RelayDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private let handleEvent: (DelegateEvent) -> Void

    init(handleEvent: @escaping (DelegateEvent) -> Void) {
        self.handleEvent = handleEvent
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handleEvent(.systemState(central.state.toSystemState()))
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advertisement = Advertisement(peripheral: peripheral, rssi: RSSI, data: advertisementData)
        handleEvent(.advertisement(peripheral.eraseToAnyPeripheral(), advertisement))
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self // weak owned
        handleEvent(.connected(peripheral.eraseToAnyPeripheral()))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        peripheral.delegate = nil
        handleEvent(.disconnected(peripheral.eraseToAnyPeripheral(), error.toDelegateError()))
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        handleEvent(.discoveredServices(peripheral.eraseToAnyPeripheral(), error.toDelegateError()))
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard let service = service.toService() else { return }
        handleEvent(.discoveredCharacteristics(peripheral.eraseToAnyPeripheral(), service, error.toDelegateError()))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let characteristic = characteristic.toCharacteristic() else { return }
        handleEvent(.updatedCharacteristic(peripheral.eraseToAnyPeripheral(), characteristic, error.toDelegateError()))
    }
}

fileprivate extension Optional where Wrapped == Error {
    func toDelegateError() -> DelegateEventError? {
        map(DelegateEventError.causedBy)
    }
}

extension CBService {
    func toService() -> Service? {
        guard let uuid = cbToUuid(uuid) else { return nil }
        let characteristics = characteristics?.compactMap { $0.toCharacteristic() } ?? []
        return Service(uuid: uuid, isPrimary: isPrimary, characteristics: characteristics)
    }
}

fileprivate extension CBCharacteristic {
    func toCharacteristic() -> Characteristic? {
        guard let uuid = cbToUuid(uuid) else { return nil }
        return Characteristic(
            uuid: uuid,
            instance: UInt32(truncatingIfNeeded: ObjectIdentifier(self).hashValue),
            properties: CharacteristicProperties(rawValue: properties.rawValue),
            value: value,
            descriptors: descriptors?.compactMap(convertDescriptor) ?? [],
            isNotifying: isNotifying)
    }
}

private func convertDescriptor(_ descriptor: CBDescriptor) -> Descriptor? {
    guard let uuid = cbToUuid(descriptor.uuid) else { return nil }
    let value: Descriptor.Value = descriptor.value.map { anyValue in
        switch anyValue {
        case let number as NSNumber:
                .number(number)
        case let string as NSString:
                .string(string as String)
        case let data as NSData:
                .data(data as Data)
        default:
                .none
        }
    } ?? .none
    return Descriptor(uuid: uuid, value: value)
}
