import Bluetooth
import JsMessage


extension WebBluetoothRequest: JsMessageRequestDecodable {

//    public static let handlerName: String = "bluetooth"

    public static func decode(from message: JsMessageRequest) -> WebBluetoothRequest? {
        guard let action = message.body["action"]?.string else { return nil }
        switch action {
        case "getAvailability":
            return .getAvailability
        case "requestDevice":
            return decodeRequestDevice(from: message.body)
        case "connect":
            return decodeConnect(from: message.body)
        case "disconnect":
            return decodeDisconnect(from: message.body)
        case "getPrimaryService":
            return decodeConnect(from: message.body)
        case "getPrimaryServices":
            return decodeConnect(from: message.body)
        case "getCharacteristic":
            return decodeConnect(from: message.body)
        case "getCharacteristics":
            return decodeConnect(from: message.body)
        default:
            return nil
        }
    }
}

private func decodeRequestDevice(from: [String: JsType]) -> WebBluetoothRequest? {
    // TODO:
    return nil
}

private func decodeConnect(from: [String: JsType]) -> WebBluetoothRequest? {
    // TODO:
    return nil
}

private func decodeDisconnect(from: [String: JsType]) -> WebBluetoothRequest? {
    // TODO:
    return nil
}

private func decodeGetPrimaryService(from: [String: JsType]) -> WebBluetoothRequest? {
    // TODO:
    return nil
}
private func decodeGetPrimaryServices(from: [String: JsType]) -> WebBluetoothRequest? {
    // TODO:
    return nil
}
private func decodeGetCharacteristic(from: [String: JsType]) -> WebBluetoothRequest? {
    // TODO:
    return nil
}
private func decodeGetCharacteristics(from: [String: JsType]) -> WebBluetoothRequest? {
    // TODO:
    return nil
}
