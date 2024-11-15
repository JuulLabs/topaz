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
        case let event as CharacteristicEvent where event.name == .characteristicValue:
            CharacteristicChangedEvent(
                peripheralId: event.peripheral.identifier,
                characteristicUuid: event.characteristic.uuid,
                characteristicInstance: event.characteristic.instance,
                data: event.characteristic.value
            )
        default:
            nil
        }
    }
}
