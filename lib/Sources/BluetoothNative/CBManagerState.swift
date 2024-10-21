import Bluetooth
import CoreBluetooth

extension CBManagerState {
    func toSystemState() -> SystemState {
        switch self {
        case .unknown: .unknown
        case .resetting: .resetting
        case .unsupported: .unsupported
        case .unauthorized: .unauthorized
        case .poweredOff: .poweredOff
        case .poweredOn: .poweredOn
        @unknown default: .unknown
        }
    }
}
