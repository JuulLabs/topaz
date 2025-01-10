import Bluetooth
import Foundation

public protocol BluetoothClient: Sendable {
    var events: AsyncStream<any BluetoothEvent> { get }

    func enable() async
    func disable() async

    func resolvePendingRequests(for event: BluetoothEvent) async
    func cancelPendingRequests() async

    func scan(filter: Filter) async -> BluetoothScanner

    func systemState() async throws -> SystemStateEvent
    func connect(_ peripheral: Peripheral) async throws -> PeripheralEvent
    func disconnect(_ peripheral: Peripheral) async throws -> PeripheralEvent
    func discoverServices(_ peripheral: Peripheral, filter: ServiceDiscoveryFilter) async throws -> ServiceDiscoveryEvent
    func discoverCharacteristics(_ peripheral: Peripheral, _ service: Service, filter: CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent
    func characteristicNotify(_ peripheral: Peripheral, _ characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEvent
    func characteristicRead(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicChangedEvent
}
