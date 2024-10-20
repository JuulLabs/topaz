import Bluetooth
import JsMessage

extension WebBluetoothResponse: JsMessageResponseEncodable {

//    public static let handlerName: String = "bluetooth"

    public func encode() -> JsMessageResponse {
        switch self {
        case let .availability(isAvailable):
            return encodeAvailability(isAvailable)
        case let .device(wat):
            return encodeDevice(wat)
        case .service(_, _):
            return encodeService()
        case .services(_, _):
            return encodeServices()
        case .characteristic(_, _, _):
            return encodeCharacteristic()
        case .characteristics(_, _, _):
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
