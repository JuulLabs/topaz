import Bluetooth
import Foundation

public struct AdvertisementEvent: DelEvent {
    public let peripheral: AnyPeripheral
    public let advertisement: Advertisement

    public init(_ peripheral: AnyPeripheral, _ advertisement: Advertisement) {
        self.peripheral = peripheral
        self.advertisement = advertisement
    }

    public var key: EventKey {
        .advertisement
    }
}

extension EventKey {
    static let advertisement = EventKey(name: .advertisement)
}
