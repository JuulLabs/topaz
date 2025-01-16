import BluetoothMessage
import Foundation
import JsMessage

struct CharacteristicRequest: JsMessageDecodable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let characteristicInstance: UInt32

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let device = data?["device"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let service = data?["service"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let characteristic = data?["characteristic"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let instance = data?["instance"]?.number?.uint32Value else {
            return nil
        }
        return .init(peripheralId: device, serviceUuid: service, characteristicUuid: characteristic, characteristicInstance: instance)
    }
}

// Response is unused on JavaScript side but needed to have `[Read|Write]Characteristic` conform to `BluetoothAction`.
struct CharacteristicResponse: JsMessageEncodable {
    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body([:])
    }
}
