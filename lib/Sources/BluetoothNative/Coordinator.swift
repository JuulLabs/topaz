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
    private var scannerCallback: ((AdvertisementEvent) -> Void)?

    let events: AsyncStream<BluetoothEvent>

    init() {
        self.queue = DispatchQueue(label: "bluetooth.live")
        self.manager = nil
        self.delegate = EventDelegate()
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
        queue.sync {
            reset()
        }
    }

    func enable() {
        queue.sync {
            guard manager == nil else {
                // TODO: warning or error for accidental re-enable here
                return
            }
            let options: [String: Any] = [
                CBCentralManagerOptionShowPowerAlertKey: false as NSNumber
            ]
            manager = CBCentralManager(delegate: delegate, queue: queue, options: options)
        }
    }

    func startScanning(filter: Filter, callback: @escaping (AdvertisementEvent) -> Void) {
        let services = filter.services.map(CBUUID.init)
        queue.sync {
            self.scannerCallback = callback
            manager?.scanForPeripherals(withServices: services, options: filter.options)
        }
    }

    func stopScanning() {
        queue.sync {
            self.scannerCallback = nil
            manager?.stopScan()
        }
    }

    func connect(peripheral: AnyPeripheral) {
        guard let native = peripheral.unerase(as: CBPeripheral.self) else { return }
        queue.sync {
            manager?.connect(native, options: nil)
        }
    }

    func disconnect(peripheral: AnyPeripheral) {
        guard let native = peripheral.unerase(as: CBPeripheral.self) else { return }
        queue.sync {
            manager?.cancelPeripheralConnection(native)
        }
    }

    func discoverServices(peripheral: AnyPeripheral, filter: ServiceDiscoveryFilter) {
        guard let native = peripheral.unerase(as: CBPeripheral.self) else { return }
        let services = filter.services?.map(CBUUID.init)
        queue.sync {
            native.discoverServices(services)
        }
    }

    func discoverCharacteristics(peripheral: AnyPeripheral, filter: CharacteristicDiscoveryFilter) {
        guard let native = peripheral.unerase(as: CBPeripheral.self) else { return }
        let serviceUuid = CBUUID(nsuuid: filter.service)
        guard let service = native.services?.first(where: {$0.uuid == serviceUuid}) else { return }
        let uuids = filter.characteristics?.map(CBUUID.init)
        queue.sync {
            native.discoverCharacteristics(uuids, for: service)
        }
    }

    func readCharacteristic(peripheral: AnyPeripheral, service: UUID, characteristic: UUID, instance: UInt32) {
        guard let native = peripheral.unerase(as: CBPeripheral.self) else { return }
        let serviceUuid = CBUUID(nsuuid: service)
        let characteristicUuid = CBUUID(nsuuid: characteristic)
        guard let nativeService = native.services?.first(where: { $0.uuid == serviceUuid }) else {
            // TODO: relocate the native object graph traversal to a throwing context to fail this case
            return
        }
        guard let nativeCharacteristic = nativeService.characteristics?.first(where: { $0.uuid == characteristicUuid && $0.instanceId == instance }) else {
            // TODO: relocate the native object graph traversal to a throwing context to fail this case
            return
        }
        queue.sync {
            native.readValue(for: nativeCharacteristic)
        }
    }
}
