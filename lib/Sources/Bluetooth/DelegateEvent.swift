
/**
 Models the various CoreBluetooth delegate events as Sendable data.
 */
public enum DelegateEvent: Equatable, Sendable {
    case systemState(SystemState)
    case advertisement(AnyPeripheral, Advertisement)
    case connected(AnyPeripheral)
    case disconnected(AnyPeripheral, BluetoothError?)
    case discoveredServices(AnyPeripheral, BluetoothError?)
    case discoveredCharacteristics(AnyPeripheral, Service, BluetoothError?)
    case updatedCharacteristic(AnyPeripheral, Characteristic, BluetoothError?)
}
