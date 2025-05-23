import Bluetooth
import BluetoothClient
import EventBus
import JsMessage

extension BluetoothError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .blocklisted: .security
        case .cancelled: .abort
        case .deviceNotConnected: .network
        case .noSuchDevice: .notFound
        case .noSuchService: .notFound
        case .noSuchCharacteristic: .notFound
        case .noSuchDescriptor: .notFound
        case .characteristicNotificationsNotSupported: .notSupported
        case .nullService: .operation
        case .nullCharacteristic: .operation
        case .turnedOff: .invalidState
        case .unauthorized: .notAllowed
        case .unavailable: .operation
        case .unknown: .unknown
        }
    }
}

extension BluetoothClientError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .causedBy: .operation
        }
    }
}

extension EventBusError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .jsContextUnavailable: .operation
        case .typeMismatch: .operation
        }
    }
}

extension OptionsError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .invalidInput: .type
        }
    }
}
