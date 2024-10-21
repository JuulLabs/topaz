import Bluetooth
import JsMessage

extension WebBluetoothEvent {
    func toJsEvent() -> JsEvent {
        switch self {
        case let .availability(isAvailable):
            encodeAvailability(isAvailable: isAvailable)
        case let .disconnected(identifier):
            encodeDisconnected(identifier: identifier)
        case .characteristicValue:
            encodeCharacteristicValue()
        }
    }
}

private func encodeAvailability(isAvailable: Bool) -> JsEvent {
    JsEvent(targetId: "bluetooth", eventName: "availabilitychanged", body: isAvailable)
}

private func encodeDisconnected(identifier: DeviceIdentifier) -> JsEvent {
    JsEvent(targetId: identifier.uuidString, eventName: "gattserverdisconnected")
}

private func encodeCharacteristicValue() -> JsEvent {
    // TODO
    JsEvent(targetId: "notimplemented", eventName: "notimplemented")
}
