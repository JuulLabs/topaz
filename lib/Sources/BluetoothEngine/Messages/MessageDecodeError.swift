import Foundation
import JsMessage

enum MessageDecodeError {
    case actionNotFound(String)
    case badRequest
    case bodyDecodeFailed(String)
}

extension MessageDecodeError: DomErrorConvertable {
    var domErrorName: DomErrorName { .encoding }
}

extension MessageDecodeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .actionNotFound(action):
            "Operation not implemented \(action)"
        case .badRequest:
            "Unable to parse request"
        case let .bodyDecodeFailed(type):
            "Decode failed for \(type)"
        }
    }
}
