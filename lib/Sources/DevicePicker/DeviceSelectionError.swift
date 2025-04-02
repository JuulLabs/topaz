import Foundation

public enum DeviceSelectionError: Error, Equatable {
    case cancelled(presentedItems: [String])
    case invalidSelection
    // TODO: timeout
}

extension DeviceSelectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .cancelled(items):
            return "Cancelled by user presentedItems=[\(items.joined(separator: ","))]"
        case .invalidSelection:
            return "Selected device is no longer available"
        }
    }
}
