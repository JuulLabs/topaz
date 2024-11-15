import Foundation

public enum BluetoothError: Error, Sendable {
    case cancelled
    case causedBy(any Error)
    case noSuchDevice(UUID)
    case noSuchService(UUID)
    case noSuchCharacteristic(service: UUID, characteristic: UUID)
    case unavailable
    case unknown
}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            "The operation was cancelled"
        case let .causedBy(error):
            error.localizedDescription
        case let .noSuchDevice(uuid):
            "No such device \(uuid.uuidString.lowercased())"
        case let .noSuchService(uuid):
            "No such service \(uuid.uuidString.lowercased())"
        case let .noSuchCharacteristic(serviceUuid, characteristicUuid):
            "No such characteristic \(characteristicUuid.uuidString.lowercased()) under service \(serviceUuid.uuidString.lowercased())"
        case .unavailable:
            "Bluetooth not available"
        case .unknown:
            "Unknown internal system error"
        }
    }
}
