import Bluetooth
import Foundation


// add start and stop to this protocol
// start and stop will return "events" 
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
    func discoverCharacteristics(_ peripheral: Peripheral, filter: CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent
    func characteristicNotify(_ peripheral: Peripheral, _ characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEvent
    func characteristicRead(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicChangedEvent

    func startNotify(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicEvent
}
