import Foundation

public enum BluetoothError: Error, Sendable {
    case cancelled
    case causedBy(any Error)
    case deviceNotConnected
    case noSuchDevice(UUID)
    case noSuchService(UUID)
    case noSuchCharacteristic(service: UUID, characteristic: UUID)
    case notSupported
    case noSuchDescriptor(characteristic: UUID, descriptor: UUID)
    case nullService(characteristic: UUID)
    case unavailable
    case unknown
}

//extension BluetoothError: Equatable {
//    public static func == (lhs: BluetoothError, rhs: BluetoothError) -> Bool {
//        switch (lhs, rhs) {
//            
////                case let (.celsius(leftValue), .celsius(rightValue)):
////                    return leftValue == rightValue
////                case let (.fahrenheit(leftValue), .fahrenheit(rightValue)):
////                    return leftValue == rightValue
////                default:
////                    return false
//        }
//    }
//    
//
//}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
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
        case .notSupported:
            "Requested action is not supported"
        case let .noSuchDescriptor(characteristicUuid, descriptorUuid):
            "No such descriptor \(descriptorUuid.uuidString.lowercased()) under characteristic \(characteristicUuid.uuidString.lowercased())"
        case let .nullService(characteristicUuid):
            "Characteristic \(characteristicUuid) is missing parent service"
        case .unavailable:
            "Bluetooth not available"
        case .unknown:
            "Unknown internal system error"
        }
    }
}
