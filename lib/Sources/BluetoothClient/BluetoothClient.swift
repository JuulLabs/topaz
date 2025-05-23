import Bluetooth
import EventBus
import Foundation

/**
 Abstracts the CoreBluetooth API as a set of synchronous methods that mostly do not
 return anything. These methods typically kick off some asynchronous operation
 that triggers some future delegate callback. The delegate callbacks are squeezed
 down to a stream of generic events for processing.
 */
public protocol BluetoothClient: Sendable {
    func enable()
    func disable()

    func startScanning(serviceUuids: [UUID])
    func stopScanning()
    func retrievePeripherals(withIdentifiers uuids: [UUID]) async -> [Peripheral]

    func connect(peripheral: Peripheral)
    func disconnect(peripheral: Peripheral)

    func discoverServices(peripheral: Peripheral, uuids serviceUuids: [UUID]?)
    func discoverCharacteristics(peripheral: Peripheral, service: Service, uuids characteristicUuids: [UUID]?)
    func discoverDescriptors(peripheral: Peripheral, characteristic: Characteristic)

    func readCharacteristic(peripheral: Peripheral, characteristic: Characteristic)
    func writeCharacteristic(peripheral: Peripheral, characteristic: Characteristic, value: Data, withResponse: Bool)
    func setNotify(peripheral: Peripheral, characteristic: Characteristic, value: Bool)

    func readDescriptor(peripheral: Peripheral, descriptor: Descriptor)
}
