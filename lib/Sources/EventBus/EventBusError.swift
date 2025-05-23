import Foundation

public enum EventBusError: Error, Equatable {
    case jsContextUnavailable
    case typeMismatch(EventName, expectedType: String)
}

extension EventBusError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .jsContextUnavailable:
            "Javascript context is not available"
        case let .typeMismatch(name, expectedType: type):
            "Type mismatch on \(name) event, expected \(type)"
        }
    }
}
