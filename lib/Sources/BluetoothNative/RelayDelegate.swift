import Bluetooth
import BluetoothClient
import CoreBluetooth
import Helpers

class EventDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let locker: LockingStrategy

    var handleEvent: (BluetoothEvent) -> Void = { _ in }

    init(locker: any LockingStrategy) {
        self.locker = locker
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handleEvent(SystemStateEvent(central.state.toSystemState()))
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advertisement = Advertisement(peripheral: peripheral, rssi: RSSI, data: advertisementData)
        handleEvent(AdvertisementEvent(peripheral.erase(locker: locker), advertisement))
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self // weak owned
        handlePeripheralEvent(.connect, peripheral, nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        peripheral.delegate = nil
        handlePeripheralEvent(.disconnect, peripheral, error)
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        let event: BluetoothEvent = if let error {
            ErrorEvent(.discoverServices, peripheral.erase(locker: locker), BluetoothError.causedBy(error))
        } else {
            ServiceDiscoveryEvent(peripheralId: peripheral.identifier, services: peripheral.erasedServices(locker: locker))
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        let event: BluetoothEvent = if let error {
            ErrorEvent(.discoverCharacteristics, peripheral.erase(locker: locker), BluetoothError.causedBy(error))
        } else {
            CharacteristicDiscoveryEvent(
                peripheralId: peripheral.identifier,
                serviceId: service.uuid.regularUuid,
                characteristics: service.erasedCharacteristics(locker: locker)
            )
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        let service = characteristic.service
        let event: BluetoothEvent = if let error {
            ErrorEvent(.discoverDescriptors, peripheral.erase(locker: locker), BluetoothError.causedBy(error))
        } else if let service {
            DescriptorDiscoveryEvent(
                peripheralId: peripheral.identifier,
                serviceId: service.uuid.regularUuid,
                characteristicId: characteristic.uuid.regularUuid,
                instance: characteristic.instanceId,
                descriptors: characteristic.erasedDescriptors(locker: locker)
            )
        } else {
            ErrorEvent(.discoverDescriptors, peripheral.erase(locker: locker), BluetoothError.nullService(characteristic: characteristic.uuid.regularUuid))
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        let event: BluetoothEvent = if let error {
            ErrorEvent(.characteristicValue, peripheral.erase(locker: locker), characteristic.erase(locker: locker), BluetoothError.causedBy(error))
        } else {
            CharacteristicChangedEvent(peripheralId: peripheral.identifier, characteristicId: characteristic.uuid.regularUuid, instance: characteristic.instanceId, data: characteristic.value)
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        guard let characteristic = descriptor.characteristic else {
            // todo: For all `BluetoothRemoteGATTDescriptor`s with matching UUID, fail all in-flight readValue() promises.
            // Without the parent characteristic, we have no way of failing the specific readValue() call.
            print("Error: Missing parent characteristic for descriptor \(descriptor.uuid.uuidString)")
            return
        }

        let event: BluetoothEvent = if let error {
            ErrorEvent(
                .descriptorValue,
                peripheral.erase(locker: locker),
                characteristic.erase(locker: locker),
                descriptor.erase(locker: locker),
                BluetoothError.causedBy(error)
            )
        } else {
            switch descriptor.valueAsData() {
            case let .success(data):
                DescriptorChangedEvent(
                    peripheralId: peripheral.identifier,
                    characteristicId: characteristic.uuid.regularUuid,
                    instance: characteristic.instanceId,
                    descriptorId: descriptor.uuid.regularUuid,
                    data: data
                )
            case let .failure(error):
                ErrorEvent(
                    .descriptorValue,
                    peripheral.erase(locker: locker),
                    characteristic.erase(locker: locker),
                    descriptor.erase(locker: locker),
                    BluetoothError.causedBy(error)
                )
            }
        }
        handleEvent(event)
    }

    private func handlePeripheralEvent(_ event: EventName, _ peripheral: CBPeripheral, _ error: (any Error)?) {
        let event: BluetoothEvent = if let error {
            ErrorEvent(event, peripheral.erase(locker: locker), BluetoothError.causedBy(error))
        } else {
            PeripheralEvent(event, peripheral.erase(locker: locker))
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {

        let eventName: EventName = characteristic.isNotifying ? .startNotifications : .stopNotifications

        let event: BluetoothEvent = if let error {
            ErrorEvent(eventName, peripheral.erase(locker: locker), characteristic.erase(locker: locker), BluetoothError.causedBy(error))
        } else {
            CharacteristicEvent(eventName, peripheralId: peripheral.identifier, characteristicId: characteristic.uuid.regularUuid, instance: characteristic.instanceId)
        }
        handleEvent(event)
    }
}

extension CBPeripheral {
    func erasedServices(locker: any LockingStrategy) -> [Service] {
        self.services?.compactMap { $0.erase(locker: locker) } ?? []
    }
}

extension CBService {
    func erasedCharacteristics(locker: any LockingStrategy) -> [Characteristic] {
        self.characteristics?.compactMap { $0.erase(locker: locker) } ?? []
    }
}

extension CBCharacteristic {
    func erasedDescriptors(locker: any LockingStrategy) -> [Descriptor] {
        self.descriptors?.compactMap { $0.erase(locker: locker) } ?? []
    }
}
