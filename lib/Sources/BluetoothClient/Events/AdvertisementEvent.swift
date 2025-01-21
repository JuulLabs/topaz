import Bluetooth

public struct AdvertisementEvent: BluetoothEvent {
    //public let name: EventName = .advertisement
    public let peripheral: Peripheral
    public let advertisement: Advertisement

    public init(_ peripheral: Peripheral, _ advertisement: Advertisement) {
        self.peripheral = peripheral
        self.advertisement = advertisement
    }

    public let lookup: EventLookup = .exact(name: .advertisement)
}
