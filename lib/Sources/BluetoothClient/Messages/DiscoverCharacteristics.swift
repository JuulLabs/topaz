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
    let peripheralId: UUID
    let characteristics: [Characteristic]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body([
            "characteristics": characteristics.map { $0.asDictionary() }
        ])
    }
}

struct DiscoverCharacteristics: BluetoothAction {
    let request: DiscoverCharacteristicsRequest

    func execute(state: BluetoothState, effector: some BluetoothEffector) async throws -> DiscoverCharacteristicsResponse {
        try await effector.bluetoothReadyState()
        let peripheral = try await state.getPeripheral(request.peripheralId)
        // todo: error response if not connected
        try await effector.runEffect(action: .discoverCharacteristics, uuid: peripheral.identifier) { client in
            client.discoverCharacteristics(peripheral, request.toCharacteristicDiscoveryFilter())
        }
        let characteristics = peripheral.services.first(where: { $0.uuid == request.serviceUuid })?.characteristics ?? []
        switch request.query {
        case let .first(characteristicUuid):
            guard let characteristic = characteristics.first else {
                throw BluetoothError.noSuchCharacteristic(service: request.serviceUuid, characteristic: characteristicUuid)
            }
            return DiscoverCharacteristicsResponse(peripheralId: peripheral.identifier, characteristics: [characteristic])
        case .all:
            return DiscoverCharacteristicsResponse(peripheralId: peripheral.identifier, characteristics: characteristics)
        }
    }
}

fileprivate extension Characteristic {
    func asDictionary() -> [String: JsConvertable] {
        return [
            "uuid": uuid.uuidString,
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

fileprivate extension DiscoverCharacteristicsRequest {
    func toCharacteristicDiscoveryFilter() -> CharacteristicDiscoveryFilter {
        let characteristics = query.characteristicUuid.map { [$0] }
        return CharacteristicDiscoveryFilter(service: serviceUuid, characteristics: characteristics)
    }
}
