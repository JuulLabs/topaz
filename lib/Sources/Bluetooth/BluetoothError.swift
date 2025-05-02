import Foundation

public enum BluetoothError: Error, Sendable {
    case blocklisted(UUID)
    case cancelled
    case causedBy(any Error)
    case deviceNotConnected
    case noSuchDevice(UUID)
    case noSuchService(UUID)
    case noSuchCharacteristic(service: UUID, characteristic: UUID)
    case characteristicNotificationsNotSupported(characteristic: UUID)
    case noSuchDescriptor(characteristic: UUID, descriptor: UUID)
    case nullService(characteristic: UUID)
    case nullCharacteristic(descriptor: UUID)
    case turnedOff
    case unauthorized
    case unavailable
    case unknown
}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .blocklisted(uuid):
            "UUID \(uuid) is on the block list"
        case .cancelled:
            "The operation was cancelled"
        case let .causedBy(error):
            error.localizedDescription
        case .deviceNotConnected:
            "Device is not connected"
        case let .noSuchDevice(uuid):
            "No such device \(uuid.uuidString.lowercased())"
        case let .noSuchService(uuid):
            "No such service \(uuid.uuidString.lowercased())"
        case let .noSuchCharacteristic(serviceUuid, characteristicUuid):
            "No such characteristic \(characteristicUuid.uuidString.lowercased()) under service \(serviceUuid.uuidString.lowercased())"
        case let .characteristicNotificationsNotSupported(uuid):
            "Characteristic \(uuid) does not support notifications"
        case let .noSuchDescriptor(characteristicUuid, descriptorUuid):
            "No such descriptor \(descriptorUuid.uuidString.lowercased()) under characteristic \(characteristicUuid.uuidString.lowercased())"
        case let .nullService(characteristicUuid):
            "Characteristic \(characteristicUuid) is missing parent service"
        case let .nullCharacteristic(descriptorUuid):
            "Descriptor \(descriptorUuid) is missing parent characteristic"
        case .turnedOff:
            "Bluetooth is turned off"
        case .unauthorized:
            "Bluetooth permissions denied"
        case .unavailable:
            "Bluetooth not available"
        case .unknown:
            "Unknown internal system error"
        }
    }
}
