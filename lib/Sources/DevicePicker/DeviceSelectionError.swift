import Foundation

public enum DeviceSelectionError: Error {
    case cancelled
    case invalidSelection
    // TODO: timeout
}

extension DeviceSelectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Cancelled by user"
        case .invalidSelection:
            return "Selected device is no longer available"
        }
    }
}
