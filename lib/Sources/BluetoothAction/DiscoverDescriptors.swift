import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct DiscoverDescriptorsRequest: JsMessageDecodable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let instance: UInt32
    let query: Query

    enum Query {
        case first(UUID)
        case all(UUID?)

        var descriptorUuid: UUID? {
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
        guard let characteristic = data?["characteristic"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let instance = data?["instance"]?.number?.uint32Value else {
            return nil
        }
        let descriptor = data?["descriptor"]?.string.flatMap(UUID.init(uuidString:))
        guard let single = data?["single"]?.number?.boolValue else {
            return nil
        }
        let query: Query? = switch (single, descriptor) {
        case (true, .none):
            nil
        case let (true, .some(descriptor)):
            .first(descriptor)
        case let (false, descriptor):
            .all(descriptor)
        }
        guard let query else { return nil }
        return .init(peripheralId: device, serviceUuid: service, characteristicUuid: characteristic, instance: instance, query: query)
    }
}

struct DiscoverDescriptorsResponse: JsMessageEncodable {
    let peripheralId: UUID
    let descriptors: [Descriptor]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body(descriptors.map { $0.uuid.uuidString.lowercased() })
    }
}

struct DiscoverDescriptors: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: DiscoverDescriptorsRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> DiscoverDescriptorsResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        // todo: error response if not connected
        let characteristic = try await state.getCharacteristic(
            peripheralId: request.peripheralId,
            serviceId: request.serviceUuid,
            characteristicId: request.characteristicUuid,
            instance: request.instance
        )
        let result = try await client.discoverDescriptors(peripheral, characteristic: characteristic)
        await state.setDescriptors(
            result.descriptors,
            on: peripheral.id,
            serviceId: result.serviceId,
            characteristicId: result.characteristicId,
            instance: result.instance
        )
        switch request.query {
        case let .first(descriptorUuid):
            guard let descriptor = result.descriptors.first else {
                throw BluetoothError.noSuchDescriptor(characteristic: request.characteristicUuid, descriptor: descriptorUuid)
            }
            return DiscoverDescriptorsResponse(peripheralId: peripheral.id, descriptors: [descriptor])
        case .all:
            return DiscoverDescriptorsResponse(peripheralId: peripheral.id, descriptors: result.descriptors)
        }
    }
}
