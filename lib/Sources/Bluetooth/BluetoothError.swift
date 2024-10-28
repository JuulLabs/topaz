import Foundation

public enum BluetoothError: Error, Sendable {
    case causedBy(any Error)
    case noSuchDevice(UUID)
    case unavailable
    case unknown
}

extension BluetoothError: Equatable {
    public static func == (lhs: BluetoothError, rhs: BluetoothError) -> Bool {
        switch (lhs, rhs) {
        case let (.causedBy(lhsError), .causedBy(rhsError)):
            // This only makes sense because the underlying NSErrors are equatable
            _isEqual(lhsError, rhsError) ?? false
        case let (.noSuchDevice(lhsUuid), .noSuchDevice(rhsUuid)):
            lhsUuid == rhsUuid
        case (.unavailable, .unavailable):
            true
        case (.unknown, .unknown):
            true
        default:
            false
        }
    }
}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .causedBy(error):
            error.localizedDescription
        case let .noSuchDevice(uuid):
            "No such device \(uuid.uuidString)"
        case .unavailable:
            "Bluetooth not available"
        case .unknown:
            "Unknown internal system error"
        }
    }
}
