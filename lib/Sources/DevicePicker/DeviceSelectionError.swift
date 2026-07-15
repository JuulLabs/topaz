import Foundation

public enum DeviceSelectionError: Error, Equatable {
    case busy
    case cancelled(presentedItems: [String])
    case invalidSelection
    case pageNotVisible
    // TODO: timeout
}

extension DeviceSelectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .busy:
            return "Another device selection is already in progress"
        case let .cancelled(items):
            return "Cancelled by user presentedItems=[\(items.joined(separator: ","))]"
        case .invalidSelection:
            return "Selected device is no longer available"
        case .pageNotVisible:
            return "Device selection requires a visible page"
        }
    }
}
