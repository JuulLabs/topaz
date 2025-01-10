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

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        let event: BluetoothEvent = if let error {
            ErrorEvent(.characteristicValue, peripheral.erase(locker: locker), characteristic.erase(locker: locker), BluetoothError.causedBy(error))
        } else {
            CharacteristicChangedEvent(peripheralId: peripheral.identifier, characteristicId: characteristic.uuid.regularUuid, instance: characteristic.instanceId, data: characteristic.value)
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

    /*
     When you enable notifications for the characteristic’s value, the peripheral calls the peripheral(_:didUpdateNotificationStateFor:error:) method of its delegate object to indicate if the action succeeded. If successful, the peripheral then calls the peripheral(_:didUpdateValueFor:error:) method of its delegate object whenever the characteristic value changes. Because the peripheral chooses when it sends an update, your app should prepare to handle them as long as notifications or indications remain enabled. If the specified characteristic’s configuration allows both notifications and indications, calling this method enables notifications only. You can disable notifications and indications for a characteristic’s value by calling this method with the enabled parameter set to false.
     */

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        //call handleEvent

        let eventName: EventName = characteristic.isNotifying ? .startNotifications : .stopNotifications

        let event: BluetoothEvent = if let error {
            ErrorEvent(eventName, peripheral.erase(locker: locker), characteristic.erase(locker: locker), BluetoothError.causedBy(error))
        } else {
//            CharacteristicChangedEvent(peripheralId: peripheral.identifier, characteristicId: characteristic.uuid.regularUuid, instance: characteristic.instanceId, data: characteristic.value)
            CharacteristicEvent(eventName, peripheralId: peripheral.identifier, characteristicId: characteristic.uuid.regularUuid, instance: characteristic.instanceId)
        }
        handleEvent(event)
    }

    /*
     *
    *  @method setNotifyValue:forCharacteristic:
    *
    *  @param enabled            Whether or not notifications/indications should be enabled.
    *  @param characteristic    The characteristic containing the client characteristic configuration descriptor.
    *
    *  @discussion                Enables or disables notifications/indications for the characteristic value of <i>characteristic</i>. If <i>characteristic</i>
    *                            allows both, notifications will be used.
    *                          When notifications/indications are enabled, updates to the characteristic value will be received via delegate method
    *                          @link peripheral:didUpdateValueForCharacteristic:error: @/link. Since it is the peripheral that chooses when to send an update,
    *                          the application should be prepared to handle them as long as notifications/indications remain enabled.
    *
    *  @see                    peripheral:didUpdateNotificationStateForCharacteristic:error:
    *  @seealso                CBConnectPeripheralOptionNotifyOnNotificationKey

   open func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
     */
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
