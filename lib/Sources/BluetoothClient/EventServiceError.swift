import Foundation

public enum EventServiceError: Error {
    case typeMismatch(EventName, expectedType: String)
}

extension EventServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .typeMismatch(name, expectedType: type):
            "Type mismatch on \(name) event, expected \(type)"
        }
    }
}
