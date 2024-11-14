import Bluetooth

public protocol BluetoothService: Sendable {
    var events: AsyncStream<DelEvent> { get }

    func scan(filter: Filter) -> Scanner

    func systemState(predicate: (@Sendable (SystemState) throws -> Bool)?) async throws -> SystemStateEvent
    func connect(_ peripheral: AnyPeripheral) async throws -> PeripheralEvent
    func disconnect(_ peripheral: AnyPeripheral) async throws -> PeripheralEvent
    func discoverServices(_ peripheral: AnyPeripheral, filter: ServiceDiscoveryFilter) async throws -> PeripheralEvent
    func discoverCharacteristics(_ peripheral: AnyPeripheral, filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEvent
    func characteristicNotify(_ peripheral: AnyPeripheral, _ characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEvent
    func characteristicRead(_ peripheral: AnyPeripheral, _ characteristic: Characteristic) async throws -> CharacteristicEvent

}

public protocol Scanner {
    var advertisements: AsyncStream<AdvertisementEvent> { get }
    func cancel()
}
