import Bluetooth
import BluetoothClient
import JsMessage

extension BluetoothError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .cancelled: .abort
        case .causedBy: .operation
        case .noSuchDevice: .notFound
        case .noSuchService: .notFound
        case .noSuchCharacteristic: .notFound
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
