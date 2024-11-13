import Bluetooth
import Foundation

extension DelegateEvent {
    func toEffect() -> BluetoothEffect {
        switch self {
        case let .systemState(systemState):
            SystemStateEffect(systemState)
        case let .advertisement(peripheral, advertisement):
            AdvertisementEffect(peripheral, advertisement)
        case let .connected(peripheral):
            PeripheralEffect(.connect, peripheral)
        case let .disconnected(peripheral, error):
            if let error {
                ErrorEffect(.disconnect, peripheral, error)
            } else {
                PeripheralEffect(.disconnect, peripheral)
            }
        case let .discoveredServices(peripheral, error):
            if let error {
                ErrorEffect(.discoverServices, peripheral, error)
            } else {
                PeripheralEffect(.discoverServices, peripheral)
            }
        case let .discoveredCharacteristics(peripheral, _, error):
            if let error {
                ErrorEffect(.discoverCharacteristics, peripheral, error)
            } else {
                PeripheralEffect(.discoverCharacteristics, peripheral)
            }
        case let .updatedCharacteristic(peripheral, characteristic, error):
            if let error {
                ErrorEffect(.characteristicValue, peripheral, characteristic, error)
            } else {
                CharacteristicEffect(.characteristicValue, peripheral, characteristic)
            }
        }
    }
}
