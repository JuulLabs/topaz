import Bluetooth
import EventBus
import Foundation

public struct MockBluetoothClient: BluetoothClient {
    public var onEnable: @Sendable () -> Void
    public var onDisable: @Sendable () -> Void
    public var onStartScanning: @Sendable (_ serviceUuids: [UUID]) -> Void
    public var onStopScanning: @Sendable () -> Void
    public var onRetrievePeripherals: @Sendable (_ uuids: [UUID]) async -> [Peripheral]
    public var onConnect: @Sendable (_ peripheral: Peripheral) -> Void
    public var onDisconnect: @Sendable (_ peripheral: Peripheral) -> Void
    public var onDiscoverServices: @Sendable (_ peripheral: Peripheral, _ serviceUuids: [UUID]?) -> Void
    public var onDiscoverCharacteristics: @Sendable (_ peripheral: Peripheral, _ service: Service, _ characteristicUuids: [UUID]?) -> Void
    public var onDiscoverDescriptors: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic) -> Void
    public var onCharacteristicSetNotifications: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ enabled: Bool) -> Void
    public var onCharacteristicRead: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic) -> Void
    public var onCharacteristicWrite: @Sendable (_ peripheral: Peripheral, _ characteristic: Characteristic, _ value: Data, _ withResponse: Bool) -> Void
    public var onDescriptorRead: @Sendable (_ peripheral: Peripheral, _ descriptor: Descriptor) -> Void

    public init() {
        self.onEnable = { fatalError("Not implemented") }
        self.onDisable = { fatalError("Not implemented") }
        self.onStartScanning = { _ in fatalError("Not implemented") }
        self.onStopScanning = { fatalError("Not implemented") }
        self.onRetrievePeripherals = { _ in fatalError("Not implemented") }
        self.onConnect = { _ in fatalError("Not implemented") }
        self.onDisconnect = { _ in fatalError("Not implemented") }
        self.onDiscoverServices = { _, _ in fatalError("Not implemented") }
        self.onDiscoverCharacteristics = { _, _, _ in fatalError("Not implemented") }
        self.onDiscoverDescriptors = { _, _ in fatalError("Not implemented") }
        self.onCharacteristicSetNotifications = { _, _, _ in fatalError("Not implemented") }
        self.onCharacteristicRead = { _, _ in fatalError("Not implemented") }
        self.onCharacteristicWrite = { _, _, _, _ in fatalError("Not implemented") }
        self.onDescriptorRead = { _, _ in fatalError("Not implemented") }
    }

    public func enable() {
        onEnable()
    }

    public func disable() {
        onDisable()
    }

    public func startScanning(serviceUuids: [UUID]) {
        onStartScanning(serviceUuids)
    }

    public func stopScanning() {
        onStopScanning()
    }

    public func retrievePeripherals(withIdentifiers uuids: [UUID]) async -> [Peripheral] {
        await onRetrievePeripherals(uuids)
    }

    public func connect(peripheral: Peripheral) {
        onConnect(peripheral)
    }

    public func disconnect(peripheral: Peripheral) {
        onDisconnect(peripheral)
    }

    public func discoverServices(peripheral: Peripheral, uuids serviceUuids: [UUID]?) {
        onDiscoverServices(peripheral, serviceUuids)
    }

    public func discoverCharacteristics(peripheral: Peripheral, service: Service, uuids characteristicUuids: [UUID]?) {
        onDiscoverCharacteristics(peripheral, service, characteristicUuids)
    }

    public func discoverDescriptors(peripheral: Peripheral, characteristic: Characteristic) {
        onDiscoverDescriptors(peripheral, characteristic)
    }

    public func readCharacteristic(peripheral: Peripheral, characteristic: Characteristic) {
        onCharacteristicRead(peripheral, characteristic)
    }

    public func writeCharacteristic(peripheral: Peripheral, characteristic: Characteristic, value: Data, withResponse: Bool) {
        onCharacteristicWrite(peripheral, characteristic, value, withResponse)
    }

    public func setNotify(peripheral: Peripheral, characteristic: Characteristic, value: Bool) {
        onCharacteristicSetNotifications(peripheral, characteristic, value)
    }

    public func readDescriptor(peripheral: Peripheral, descriptor: Descriptor) {
        onDescriptorRead(peripheral, descriptor)
    }
}
