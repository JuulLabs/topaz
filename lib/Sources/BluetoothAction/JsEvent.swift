import Bluetooth
import BluetoothClient
import BluetoothMessage
import JsMessage

extension BluetoothEvent {
    public func toJsEvent() -> JsEvent? {
        switch self {
        case let event as SystemStateEvent:
            event.availabilityChangedEvent()
        case let event as DisconnectionEvent:
            event.gattServerDisconnectedEvent()
        case let event as CharacteristicChangedEvent:
            event.characteristicValueChangedEvent()
        default:
            nil
        }
    }
}
