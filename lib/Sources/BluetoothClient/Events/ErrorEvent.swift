import Bluetooth
import Foundation

public struct ErrorEvent: BluetoothEvent {
    public let lookup: EventLookup
    public let error: any Error

    public init(error: any Error, lookup: EventLookup) {
        self.error = error
        self.lookup = lookup
    }
}
