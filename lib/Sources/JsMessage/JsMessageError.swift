import Foundation

/// Errors common to JS message decoding/dispatch, shared across processors.
public enum JsMessageError: Error {
    case actionNotFound(String)
    case badRequest
    case notImplemented
}

extension JsMessageError: DomErrorConvertable {
    public var domErrorName: DomErrorName {
        switch self {
        case .actionNotFound: .encoding
        case .badRequest: .encoding
        case .notImplemented: .notSupported
        }
    }
}

extension JsMessageError: LocalizedError {
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
