import Bluetooth
import BluetoothClient
import CoreBluetooth
import Helpers

/**
 Stateless system for relaying messages to/from CoreBluetooth.
 All operations run synchronously on the same queue as CoreBlutooth.
 */
class Coordinator: @unchecked Sendable {
    private let queue: DispatchQueue // TODO: from dependencies
    private var manager: CBCentralManager?
    private let delegate: EventDelegate
    private var scannerCallback: (@Sendable (AdvertisementEvent) -> Void)?

    let events: AsyncStream<BluetoothEvent>

    init() {
        let queue = DispatchQueue(label: "bluetooth.live")
        self.queue = queue
        self.manager = nil
        self.delegate = EventDelegate(locker: QueueLockingStrategy(queue: queue))
        let (stream, contination) = AsyncStream<BluetoothEvent>.makeStream()
        self.events = stream
        delegate.handleEvent = { [weak self] event in
            if let advertisement = event as? AdvertisementEvent {
                self?.scannerCallback?(advertisement)
            }
            contination.yield(event)
        }
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

    func startScanning(filter: Filter, callback: @escaping @Sendable (AdvertisementEvent) -> Void) {
        queue.async {
            let services = filter.services.map(CBUUID.init)
            self.scannerCallback = callback
            self.manager?.scanForPeripherals(withServices: services, options: filter.options)
        }
    }

    func stopScanning() {
        queue.async {
            self.scannerCallback = nil
            self.manager?.stopScan()
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

    func readDescriptor(peripheral: Peripheral, descriptor: Descriptor) {
        queue.async {
            guard let nativePeripheral = peripheral.rawValue else { return }
            guard let nativeDescriptor = descriptor.rawValue else { return }
            nativePeripheral.readValue(for: nativeDescriptor)
        }
    }
}
