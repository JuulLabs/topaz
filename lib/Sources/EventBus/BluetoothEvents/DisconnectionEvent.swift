import Bluetooth

public enum DisconnectionEvent: BluetoothEvent {
    case requested(Peripheral)
    case unexpected(Peripheral, any Error)

    public var peripheral: Peripheral {
        switch self {
        case let .requested(peripheral): peripheral
        case let .unexpected(peripheral, _): peripheral
        }
    }

    public var lookup: EventLookup {
        .exact(key: .peripheral(.disconnect, peripheral))
    }
}
