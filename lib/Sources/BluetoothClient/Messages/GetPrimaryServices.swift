import Bluetooth
import Foundation
import JsMessage

struct GetPrimaryServicesRequest: JsMessageDecodable, PeripheralIdentifiable {
    let peripheralId: UUID
    let serviceUuid: UUID?

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        let serviceUuid = data?["bluetoothServiceUUID"]?.string.flatMap(UUID.init(uuidString:))
        return .init(peripheralId: uuid, serviceUuid: serviceUuid)
    }
}

struct GetPrimaryServicesResponse: JsMessageEncodable {
    let peripheralId: UUID
    let primaryServices: [Service]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body([
            "services": primaryServices.map { $0.uuid.uuidString }
        ])
    }
}
