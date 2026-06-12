import Foundation
import JsMessage

enum AppMessageError {
    case actionNotFound(String)
    case badRequest
    case notImplemented
    case userAgentModeChangeFailed
}

extension AppMessageError: DomErrorConvertable {
    var domErrorName: DomErrorName {
        switch self {
        case .actionNotFound: .encoding
        case .badRequest: .encoding
        case .notImplemented: .notSupported
        case .userAgentModeChangeFailed: .operation
        }
    }
}

extension AppMessageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .actionNotFound(action):
            "Operation not implemented \(action)"
        case .badRequest:
            "Unable to parse request"
        case .notImplemented:
            "Operation not implemented"
        case .userAgentModeChangeFailed:
            "Unable to change user agent mode"
        }
    }
}
