import Bluetooth
import Foundation
import JsMessage

struct DiscoverCharacteristicsRequest: JsMessageDecodable, PeripheralIdentifiable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let query: Query

    enum Query {
        case first(UUID)
        case all(UUID?)

        var characteristicUuid: UUID? {
            switch self {
            case let .first(uuid):
                uuid
            case let .all(uuid):
                uuid
            }
        }
    }

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let single = data?["single"]?.number?.boolValue else {
            return nil
        }
        guard let service = data?["service"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        let characteristic = data?["characteristic"]?.string.flatMap(UUID.init(uuidString:))
        let query: Query? = switch (single, characteristic) {
        case (true, .none):
            nil
        case let (true, .some(characteristic)):
            .first(characteristic)
        case let (false, characteristic):
            .all(characteristic)
        }
        guard let query else { return nil }
        return .init(peripheralId: uuid, serviceUuid: service, query: query)
    }
}

struct DiscoverCharacteristicsResponse: JsMessageEncodable {
    let peripheralId: UUID
    let characteristics: [Characteristic]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body([
            "characteristics": characteristics.toJsConvertable()
        ])
    }
}

fileprivate extension Array where Element == Characteristic {
    func toJsConvertable() -> [JsConvertable] {
        return self.map {
            [
                "uuid": $0.uuid.uuidString,
                "properties": $0.properties.toJsConvertable(),
            ]
        }
    }
}

fileprivate extension CharacteristicProperties {
    func toJsConvertable() -> JsConvertable {
        return [
            "authenticatedSignedWrites": self.contains(.authenticatedSignedWrites),
            "broadcast": self.contains(.broadcast),
            "indicate": self.contains(.indicate),
            "notify": self.contains(.notify),
            "read": self.contains(.read),
            "reliableWrite": false, // No equivalent property in Core Bluetooth.
            "writableAuxiliaries": false, // No equivalent property in Core Bluetooth.
            "write": self.contains(.write),
            "writeWithoutResponse": self.contains(.writeWithoutResponse),
        ]
    }
}
