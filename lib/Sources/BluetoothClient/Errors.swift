import Bluetooth
import JsMessage

extension BluetoothError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .causedBy: .unknown
        case .noSuchDevice: .notFound
        case .unavailable: .unknown
        case .unknown: .unknown
        }
    }
}
