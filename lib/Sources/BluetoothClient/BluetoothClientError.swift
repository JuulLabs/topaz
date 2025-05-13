import Foundation

public enum BluetoothClientError: Error, Sendable {
    case causedBy(any Error)
}

extension BluetoothClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .causedBy(error):
            error.localizedDescription
        }
    }
}
