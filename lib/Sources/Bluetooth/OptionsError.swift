import Foundation

public enum OptionsError: Equatable {
    case invalidInput(String)
}

extension OptionsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidInput(reason):
            "Invalid options: \(reason)"
        }
    }
}
