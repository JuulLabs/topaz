import Bluetooth
import JsMessage

extension BluetoothError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .cancelled: .abort
        case .causedBy: .operataion
        case .noSuchDevice: .notFound
        case .noSuchService: .notFound
        case .noSuchCharacteristic: .notFound
        case .unavailable: .operataion
        case .unknown: .unknown
        }
    }
}
