import Bluetooth
import Foundation
import JsMessage

struct ConnectRequest: JsMessageDecodable, PeripheralIdentifiable {
    let peripheralId: UUID

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        return .init(peripheralId: uuid)
    }
}

struct ConnectResponse: JsMessageEncodable {
    let isConnected: Bool = true

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body(["connected": isConnected])
    }
}
