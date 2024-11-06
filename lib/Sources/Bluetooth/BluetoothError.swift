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
            "No such device \(uuid.uuidString)"
        case let .noSuchService(uuid):
            "No such service \(uuid.uuidString)"
        case let .noSuchCharacteristic(serviceUuid, characteristicUuid):
            "No such characteristic \(characteristicUuid.uuidString) under service \(serviceUuid.uuidString)"
        case .unavailable:
            "Bluetooth not available"
        case .unknown:
            "Unknown internal system error"
        }
    }
}
