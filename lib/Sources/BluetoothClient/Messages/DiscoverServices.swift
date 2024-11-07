import Bluetooth
import Foundation
import JsMessage

struct DiscoverServicesRequest: JsMessageDecodable, PeripheralIdentifiable {
    let peripheralId: UUID
    let query: Query

    enum Query {
        case first(UUID)
        case all(UUID?)

        var serviceUuid: UUID? {
            switch self {
            case let .first(uuid):
                uuid
            case let .all(uuid):
                uuid
            }
        }
    }

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let device = data?["device"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        let serviceUuid = data?["service"]?.string.flatMap(UUID.init(uuidString:))
        guard let single = data?["single"]?.number?.boolValue else {
            return nil
        }
        let query: Query? = switch (single, serviceUuid) {
        case (true, .none):
            nil
        case let (true, .some(service)):
            .first(service)
        case let (false, service):
            .all(service)
        }
        guard let query else { return nil }
        return .init(peripheralId: device, query: query)
    }
}

struct DiscoverServicesResponse: JsMessageEncodable {
    let peripheralId: UUID
    let services: [Service]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body([
            "services": services.map { $0.uuid.uuidString }
        ])
    }
}
