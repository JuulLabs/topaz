import Bluetooth
import BluetoothClient
import CoreBluetooth
import EventBus
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
        handlePeripheralEvent(.connect, peripheral: peripheral, error: nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        peripheral.delegate = nil
        let event = if let error {
            DisconnectionEvent.unexpected(peripheral.erase(locker: locker), error)
        } else {
            DisconnectionEvent.requested(peripheral.erase(locker: locker))
        }
        handleEvent(event)
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        let event: BluetoothEvent = if let error {
            ErrorEvent(error: BluetoothClientError.causedBy(error), lookup: .exact(name: .discoverServices, peripheralId: peripheral.identifier))
        } else {
            ServiceDiscoveryEvent(peripheralId: peripheral.identifier, services: peripheral.erasedServices(locker: locker))
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        let event: BluetoothEvent
        if let error {
            event = ErrorEvent(
                error: BluetoothClientError.causedBy(error),
                lookup: .exact(name: .discoverCharacteristics, peripheralId: peripheral.identifier, serviceId: service.uuid.regularUuid)
            )
        } else {
            uniquifyCharacteristics(on: service)
            event = CharacteristicDiscoveryEvent(
                peripheralId: peripheral.identifier,
                serviceId: service.uuid.regularUuid,
                characteristics: service.erasedCharacteristics(locker: locker)
            )
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        let serviceOrError = serviceOrErrorForCharacteristicEvent(.discoverDescriptors, peripheral: peripheral, characteristic: characteristic, error: error)
        let event: BluetoothEvent = switch serviceOrError {
        case let .service(service):
            DescriptorDiscoveryEvent(
                peripheralId: peripheral.identifier,
                serviceId: service.uuid.regularUuid,
                characteristicId: characteristic.uuid.regularUuid,
                instance: characteristic.instanceId,
                descriptors: characteristic.erasedDescriptors(locker: locker)
            )
        case let .error(errorEvent):
            errorEvent
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        let serviceOrError = serviceOrErrorForCharacteristicEvent(.characteristicValue, peripheral: peripheral, characteristic: characteristic, error: error)
        let event: BluetoothEvent = switch serviceOrError {
        case let .service(service):
            CharacteristicChangedEvent(
                peripheralId: peripheral.identifier,
                serviceId: service.uuid.regularUuid,
                characteristicId: characteristic.uuid.regularUuid,
                instance: characteristic.instanceId,
                data: characteristic.value
            )
        case let .error(errorEvent):
            errorEvent
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        guard let characteristic = descriptor.characteristic else {
            let cause: any Error = error.map(BluetoothClientError.causedBy) ?? BluetoothError.nullCharacteristic(descriptor: descriptor.uuid.regularUuid)
            let errorEvent = ErrorEvent(
                error: cause,
                lookup: .wildcard(
                    name: .descriptorValue,
                    peripheralId: peripheral.identifier,
                    descriptorId: descriptor.uuid.regularUuid
                )
            )
            handleEvent(errorEvent)
            return
        }
        let eventKey = EventRegistrationKey(
            name: .descriptorValue,
            peripheralId: peripheral.identifier,
            characteristicId: characteristic.uuid.regularUuid,
            characteristicInstance: characteristic.instanceId,
            descriptorId: descriptor.uuid.regularUuid
        )
        let event: BluetoothEvent = if let error {
            ErrorEvent(error: BluetoothClientError.causedBy(error), lookup: .exact(key: eventKey))
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
                ErrorEvent(error: BluetoothClientError.causedBy(error), lookup: .exact(key: eventKey))
            }
        }
        handleEvent(event)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        handleCharacteristicEvent(.characteristicWrite, peripheral: peripheral, characteristic: characteristic, error: error)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        handleCharacteristicEvent(.characteristicNotify, peripheral: peripheral, characteristic: characteristic, error: error)
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        handlePeripheralEvent(.canSendWriteWithoutResponse, peripheral: peripheral, error: nil)
    }

    private func handlePeripheralEvent(_ event: EventName, peripheral: CBPeripheral, error: (any Error)?) {
        let event: BluetoothEvent = if let error {
            ErrorEvent(error: BluetoothClientError.causedBy(error), lookup: .exact(name: event, peripheralId: peripheral.identifier))
        } else {
            PeripheralEvent(event, peripheral.erase(locker: locker))
        }
        handleEvent(event)
    }

    private func handleCharacteristicEvent(_ event: EventName, peripheral: CBPeripheral, characteristic: CBCharacteristic, error: (any Error)?) {
        let serviceOrError = serviceOrErrorForCharacteristicEvent(event, peripheral: peripheral, characteristic: characteristic, error: error)
        let event: BluetoothEvent = switch serviceOrError {
        case let .service(service):
            CharacteristicEvent(
                event,
                peripheralId: peripheral.identifier,
                serviceId: service.uuid.regularUuid,
                characteristicId: characteristic.uuid.regularUuid,
                instance: characteristic.instanceId
            )
        case let .error(errorEvent):
            errorEvent
        }
        handleEvent(event)
    }

    private func serviceOrErrorForCharacteristicEvent(
        _ event: EventName,
        peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        error: (any Error)?
    ) -> ServiceOrError {
        guard let service = characteristic.service else {
            // If there is no service we cannot target the requestor precisely so fail using a wildcard key
            let cause: any Error = error.map(BluetoothClientError.causedBy) ?? BluetoothError.nullService(characteristic: characteristic.uuid.regularUuid)
            return .error(
                ErrorEvent(
                    error: cause,
                    lookup: .wildcard(
                        name: event,
                        peripheralId: peripheral.identifier,
                        characteristicId: characteristic.uuid.regularUuid,
                        characteristicInstance: characteristic.instanceId
                    )
                )
            )
        }
        if let error {
            // An error occured and we know the service so target the requestor with the exact key
            return .error(
                ErrorEvent(
                    error: BluetoothClientError.causedBy(error),
                    lookup: .exact(
                        key: .characteristic(
                            event,
                            peripheralId: peripheral.identifier,
                            serviceId: service.uuid.regularUuid,
                            characteristicId: characteristic.uuid.regularUuid,
                            instance: characteristic.instanceId
                        )
                    )
                )
            )
        }
        return .service(service)
    }

    // For differentiation of duplicate characteristics, we pretty much have to assume that:
    // 1. The characteristics are returned in the same order every time
    // 2. We are always provided a complete list of characteristics on the service
    private func uniquifyCharacteristics(on service: CBService) {
        guard let characteristics = service.characteristics else { return }
        var uuids = [CBUUID: UInt32]()
        for characteristic in characteristics {
            if let instance = uuids[characteristic.uuid] {
                characteristic.instanceId = instance + 1
            } else {
                characteristic.instanceId = 0
            }
            uuids[characteristic.uuid] = characteristic.instanceId
        }
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

private enum ServiceOrError {
    case service(CBService)
    case error(ErrorEvent)
}
