import Bluetooth
import BluetoothClient
import JsMessage

extension BluetoothError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .blocklisted: .security
        case .cancelled: .abort
        case .causedBy: .operation
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

extension EventServiceError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
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
