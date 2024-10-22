import Bluetooth
import JsMessage

extension WebBluetoothResponse: JsMessageResponseEncodable {

    public func encode() -> JsMessageResponse {
        switch self {
        case let .availability(isAvailable):
            return encodeAvailability(isAvailable)
        case let .device(id):
            return encodeDevice(id)
        case .service:
            return encodeService()
        case .services:
            return encodeServices()
        case .characteristic:
            return encodeCharacteristic()
        case .characteristics:
            return encodeCharacteristics()
        }
    }
}

private func encodeAvailability(_ isAvailable: Bool) -> JsMessageResponse {
    return .body(["isAvailable": isAvailable])
}

private func encodeDevice(_ id: DeviceIdentifier) -> JsMessageResponse {
    return .body([
        "device": id.uuidString,
        "name": jsNull, // TODO
    ])
}

private func encodeService() -> JsMessageResponse {
    // TODO
    return .body([:])
}

private func encodeServices() -> JsMessageResponse {
    // TODO
    return .body([:])
}

private func encodeCharacteristic() -> JsMessageResponse {
    // TODO
    return .body([:])
}

private func encodeCharacteristics() -> JsMessageResponse {
    // TODO
    return .body([:])
}
