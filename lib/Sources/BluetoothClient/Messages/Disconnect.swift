import Bluetooth
import Foundation
import JsMessage

struct DisconnectRequest: JsMessageDecodable, PeripheralIdentifiable {
    let peripheralId: UUID

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        return .init(peripheralId: uuid)
    }
}

struct DisconnectResponse: JsMessageEncodable {
    let peripheralId: UUID
    let isDisconnected: Bool = true

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body(["disconnected": isDisconnected])
    }
}

struct DisconnectEvent: JsEventEncodable {
    let peripheralId: UUID

    func toJsEvent() -> JsEvent {
        JsEvent(targetId: peripheralId.uuidString, eventName: "gattserverdisconnected")
    }
}
