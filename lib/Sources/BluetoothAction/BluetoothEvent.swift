import Bluetooth
import BluetoothClient
import BluetoothMessage

extension BluetoothEvent {
    public func toJsEvent() -> JsEventEncodable? {
        switch self {
        case let event as SystemStateEvent:
            AvailabilityEvent(state: event.systemState)
        case let event as PeripheralEvent where event.name == .disconnect:
            // TODO: can we forward the error case here somehow?
            DisconnectEvent(peripheralId: event.peripheral.identifier)
        default:
            nil
        }
    }
}
