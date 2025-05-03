import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct DiscoverCharacteristicsRequest: JsMessageDecodable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let query: Query

    var filter: CharacteristicDiscoveryFilter {
        let characteristics = query.characteristicUuid.map { [$0] }
        return CharacteristicDiscoveryFilter(service: serviceUuid, characteristics: characteristics)
    }

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
        guard let device = data?["device"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let service = data?["service"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        let characteristic = data?["characteristic"]?.string.flatMap(UUID.init(uuidString:))
        guard let single = data?["single"]?.number?.boolValue else {
            return nil
        }
        let query: Query? = switch (single, characteristic) {
        case (true, .none):
            nil
        case let (true, .some(characteristic)):
            .first(characteristic)
        case let (false, characteristic):
            .all(characteristic)
        }
        guard let query else { return nil }
        return .init(peripheralId: device, serviceUuid: service, query: query)
    }
}

struct DiscoverCharacteristicsResponse: JsMessageEncodable {
    let characteristics: [Characteristic]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body([
            "characteristics": characteristics.map { $0.asDictionary() }
        ])
    }
}

struct DiscoverCharacteristics: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: DiscoverCharacteristicsRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> DiscoverCharacteristicsResponse {
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let result = try await client.discoverCharacteristics(peripheral, filter: request.filter)
        await state.setCharacteristics(result.characteristics, on: peripheral.id, serviceId: result.serviceId)
        switch request.query {
        case let .first(characteristicUuid):
            guard let characteristic = result.characteristics.first else {
                throw BluetoothError.noSuchCharacteristic(service: request.serviceUuid, characteristic: characteristicUuid)
            }
            return DiscoverCharacteristicsResponse(characteristics: [characteristic])
        case .all:
            return DiscoverCharacteristicsResponse(characteristics: result.characteristics)
        }
    }
}

fileprivate extension Characteristic {
    func asDictionary() -> [String: JsConvertable] {
        return [
            "uuid": uuid,
            "instance": instance,
            "properties": properties.asDictionary(),
        ]
    }
}

fileprivate extension CharacteristicProperties {
    func asDictionary() -> [String: JsConvertable] {
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
