import Bluetooth
import Foundation

public protocol BluetoothEvent: Sendable {
    var lookup: EventLookup { get }
}
