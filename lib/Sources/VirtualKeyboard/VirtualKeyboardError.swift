import Foundation
import JsMessage

enum VirtualKeyboardError {
    case actionNotFound(String)
    case badRequest
    case notImplemented
}

extension VirtualKeyboardError: DomErrorConvertable {
    var domErrorName: DomErrorName {
        switch self {
        case .actionNotFound: .encoding
        case .badRequest: .encoding
        case .notImplemented: .notSupported
        }
    }
}

extension VirtualKeyboardError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .actionNotFound(action):
            "Operation not implemented \(action)"
        case .badRequest:
            "Unable to parse request"
        case .notImplemented:
            "Operation not implemented"
        }
    }
}
