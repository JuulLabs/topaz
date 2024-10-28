import Bluetooth
import Foundation
import JsMessage

struct RequestDeviceRequest: JsMessageDecodable {
    let filter: Filter

    static func decode(from data: [String: JsType]?) -> Self? {
        return .init(filter: .decode(from: data))
    }
}

struct RequestDeviceResponse: JsMessageEncodable {
    let peripheralId: UUID
    let name: JsConvertable?

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body([
            "uuid": peripheralId.uuidString,
            "name": name,
        ])
    }
}
