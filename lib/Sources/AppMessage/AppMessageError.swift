import Foundation
import JsMessage

enum AppMessageError {
    case userAgentModeChangeFailed
}

extension AppMessageError: DomErrorConvertable {
    var domErrorName: DomErrorName {
        switch self {
        case .userAgentModeChangeFailed: .operation
        }
    }
}

extension AppMessageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .userAgentModeChangeFailed:
            "Unable to change user agent mode"
        }
    }
}
