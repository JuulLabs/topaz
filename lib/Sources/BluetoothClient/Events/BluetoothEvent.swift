import Bluetooth

public protocol BluetoothEvent: Sendable {
    var name: EventName { get }
    var key: EventKey { get }
}
