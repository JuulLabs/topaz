import Bluetooth
import CoreBluetooth
import Helpers

/**
 Stateless system for relaying messages to/from CoreBluetooth.
 All operations run synchronously on the same queue as CoreBlutooth.
 */
class Coordinator: @unchecked Sendable {
    private let queue: DispatchQueue // TODO: from dependencies
    private var manager: CBCentralManager?
    private let delegate: RelayDelegate

    let events: EmissionStream<DelegateEvent>

    init() {
        self.queue = DispatchQueue(label: "bluetooth.live")
        self.manager = nil
        let eventStream = EmissionStream<DelegateEvent>()
        self.events = eventStream
        self.delegate = RelayDelegate(handleEvent: eventStream.emit)
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
            let options: [String:Any] = [
                CBCentralManagerOptionShowPowerAlertKey: NSNumber(booleanLiteral: false)
            ]
            manager = CBCentralManager(delegate: delegate, queue: queue, options: options)
        }
    }

    func startScanning(filter: Filter) {
        let services = filter.services.map(CBUUID.init)
        queue.sync {
            manager?.scanForPeripherals(withServices: services, options: filter.options)
        }
    }

    func stopScanning() {
        queue.sync {
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
}
