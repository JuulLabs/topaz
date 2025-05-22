import Bluetooth
import BluetoothClient
import CoreBluetooth
import Dispatch
import Helpers

/**
 Stateless system for relaying messages to/from CoreBluetooth.
 All operations run synchronously on the same queue as CoreBlutooth.
 */
class Coordinator: @unchecked Sendable, BluetoothClientV2 {
    private let queue: DispatchQueue
    private let locker: LockingStrategy
    private var manager: CBCentralManager?
    private let delegate: (CBCentralManagerDelegate & CBPeripheralDelegate)?

    init(
        queue: DispatchQueue,
        locker: LockingStrategy,
        delegate: (CBCentralManagerDelegate & CBPeripheralDelegate)? = nil
    ) {
        self.queue = queue
        self.locker = locker
        self.delegate = delegate
        self.manager = nil
    }

    deinit {
        reset()
    }

    private func reset() {
        if let oldManager = manager {
            oldManager.delegate = nil
            oldManager.stopScan()
        }
        manager = nil
    }

    func currentState() -> CBManagerState {
        queue.sync {
            manager?.state ?? .unknown
        }
    }

    func disable() {
        queue.async {
            self.reset()
        }
    }

    func enable() {
        queue.async {
            guard self.manager == nil else {
                // TODO: warning or error for accidental re-enable here
                return
            }
            let options: [String: Any] = [
                CBCentralManagerOptionShowPowerAlertKey: false as NSNumber
            ]
            self.manager = CBCentralManager(delegate: self.delegate, queue: self.queue, options: options)
        }
    }

    func startScanning(serviceUuids: [UUID]) {
        queue.async {
            let services = serviceUuids.map(CBUUID.init)
            self.manager?.scanForPeripherals(withServices: services, options: nil) // TODO: Configure CoreBluetooth scanner options
        }
    }

    func stopScanning() {
        queue.async {
            self.manager?.stopScan()
        }
    }

    func retrievePeripherals(withIdentifiers uuids: [UUID]) async -> [Peripheral] {
        queue.sync {
            self.manager?.retrievePeripherals(withIdentifiers: uuids) ?? []
        }.map { peripheral in
            peripheral.erase(locker: locker)
        }
    }

    func connect(peripheral: Peripheral) {
        queue.async {
            guard let native = peripheral.rawValue else { return }
            self.manager?.connect(native, options: nil)
        }
    }

    func disconnect(peripheral: Peripheral) {
        queue.async {
            guard let native = peripheral.rawValue else { return }
            self.manager?.cancelPeripheralConnection(native)
        }
    }

    func discoverServices(peripheral: Peripheral, uuids serviceUuids: [UUID]?) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            let uuids = serviceUuids?.map(CBUUID.init)
            nativePeripheral.discoverServices(uuids)
        }
    }

    func discoverCharacteristics(peripheral: Peripheral, service: Service, uuids characteristicUuids: [UUID]?) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            guard let nativeService = service.rawValue else { return }
            let uuids = characteristicUuids?.map(CBUUID.init)
            nativePeripheral.discoverCharacteristics(uuids, for: nativeService)
        }
    }

    func discoverDescriptors(peripheral: Peripheral, characteristic: Characteristic) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            guard let nativeCharacteristic = characteristic.rawValue else { return }
            nativePeripheral.discoverDescriptors(for: nativeCharacteristic)
        }
    }

    func readCharacteristic(peripheral: Peripheral, characteristic: Characteristic) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            guard let nativeCharacteristic = characteristic.rawValue else { return }
            nativePeripheral.readValue(for: nativeCharacteristic)
        }
    }

    func writeCharacteristic(peripheral: Peripheral, characteristic: Characteristic, value: Data, withResponse: Bool) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            guard let nativeCharacteristic = characteristic.rawValue else { return }
            nativePeripheral.writeValue(value, for: nativeCharacteristic, type: withResponse ? .withResponse : .withoutResponse)
        }
    }

    func readDescriptor(peripheral: Peripheral, descriptor: Descriptor) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            guard let nativeDescriptor = descriptor.rawValue else { return }
            nativePeripheral.readValue(for: nativeDescriptor)
        }
    }

    func setNotify(peripheral: Peripheral, characteristic: Characteristic, value: Bool) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            guard let nativeCharacteristic = characteristic.rawValue else { return }
            nativePeripheral.setNotifyValue(value, for: nativeCharacteristic)
        }
    }
}
