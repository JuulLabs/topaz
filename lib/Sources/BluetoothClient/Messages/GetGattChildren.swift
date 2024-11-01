import Bluetooth
import Foundation
import JsMessage

struct GetGattChildrenRequest: JsMessageDecodable, PeripheralIdentifiable {
    let peripheralId: UUID
    let single: Bool
    let serviceUuid: UUID?

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let single = data?["single"]?.number?.boolValue else {
            return nil
        }
        let serviceUuid = data?["bluetoothServiceUUID"]?.string.flatMap(UUID.init(uuidString:))
        return .init(peripheralId: uuid, single: single, serviceUuid: serviceUuid)
    }
}

struct GetGattChildrenResponse: JsMessageEncodable {
    let peripheralId: UUID
    let services: [Service]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body([
            "services": services.map { $0.uuid.uuidString }
        ])
    }
}
