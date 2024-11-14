import Bluetooth
import JsMessage

extension BluetoothError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .cancelled: .abort
        case .causedBy: .unknown
        case .noSuchDevice: .notFound
        case .noSuchService: .notFound
        case .noSuchCharacteristic: .notFound
        case .unavailable: .unknown
        case .unknown: .unknown
        }
    }
}

extension DelegateEventError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .causedBy: .operataion
        }
    }
}
