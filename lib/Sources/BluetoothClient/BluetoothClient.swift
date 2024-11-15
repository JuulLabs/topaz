import Bluetooth

public protocol BluetoothClient: Sendable {
    var events: AsyncStream<any BluetoothEvent> { get }

    func enable() async
    func disable() async

    func scan(filter: Filter) async -> BluetoothScanner

    func systemState() async throws -> SystemStateEvent
    func connect(_ peripheral: AnyPeripheral) async throws -> PeripheralEvent
    func disconnect(_ peripheral: AnyPeripheral) async throws -> PeripheralEvent
    func discoverServices(_ peripheral: AnyPeripheral, filter: ServiceDiscoveryFilter) async throws -> PeripheralEvent
    func discoverCharacteristics(_ peripheral: AnyPeripheral, filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEvent
    func characteristicNotify(_ peripheral: AnyPeripheral, _ characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEvent
    func characteristicRead(_ peripheral: AnyPeripheral, _ characteristic: Characteristic) async throws -> CharacteristicEvent
}
