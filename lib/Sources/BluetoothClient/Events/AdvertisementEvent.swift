import Bluetooth

public struct AdvertisementEvent: BluetoothEvent {
    public let name: EventName = .advertisement
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
    public static let advertisement = EventKey(name: .advertisement)
}
