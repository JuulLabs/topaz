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
    func discoverCharacteristics(_ peripheral: Peripheral, filter: CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent
    func discoverDescriptors(_ peripheral: Peripheral, _ characteristic: Characteristic) async throws -> DescriptorDiscoveryEvent
    func characteristicNotify(_ peripheral: Peripheral, _ characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEvent
    func characteristicRead(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicChangedEvent
    func characteristicWrite(_ peripheral: Peripheral, characteristic: Characteristic, value: Data, withResponse: Bool) async throws -> CharacteristicEvent
    func descriptorRead(_ peripheral: Peripheral, characteristic: Characteristic, descriptor: Descriptor) async throws -> DescriptorChangedEvent
    func startNotifications(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicEvent
    func stopNotifications(_ peripheral: Peripheral, characteristic: Characteristic) async throws -> CharacteristicEvent
}
