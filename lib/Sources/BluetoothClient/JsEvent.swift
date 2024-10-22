import Bluetooth
import JsMessage

extension WebBluetoothEvent {
    func toJsEvent() -> JsEvent {
        switch self {
        case let .disconnected(identifier):
            encodeDisconnected(identifier: identifier)
        case .characteristicValue:
            encodeCharacteristicValue()
        }
    }
}

private func encodeDisconnected(identifier: DeviceIdentifier) -> JsEvent {
    JsEvent(targetId: identifier.uuidString, eventName: "disconnected", body: nil)
}

private func encodeCharacteristicValue() -> JsEvent {
    // TODO
    JsEvent(targetId: "notimplemented", eventName: "notimplemented", body: nil)
}
