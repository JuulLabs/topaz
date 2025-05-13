import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage
import SecurityList

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
    let descriptors: [Descriptor]

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body(descriptors.map { $0.uuid })
    }
}

struct DiscoverDescriptors: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: DiscoverDescriptorsRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> DiscoverDescriptorsResponse {
        try await checkSecurityList(securityList: state.securityList)
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (_, characteristic) = try await state.getCharacteristic(
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
            // Result is not filtered, so do so now by taking the first match:
            guard let descriptor = result.descriptors.first(where: { $0.uuid == descriptorUuid }) else {
                throw BluetoothError.noSuchDescriptor(characteristic: request.characteristicUuid, descriptor: descriptorUuid)
            }
            return DiscoverDescriptorsResponse(descriptors: [descriptor])
        case .all:
            // Result is not filtered, so do so now by taking all that match:
            if let descriptorUuid = request.query.descriptorUuid {
                let descriptors = result.descriptors.filter { $0.uuid == descriptorUuid }
                guard !descriptors.isEmpty else {
                    throw BluetoothError.noSuchDescriptor(characteristic: request.characteristicUuid, descriptor: descriptorUuid)
                }
                return DiscoverDescriptorsResponse(descriptors: descriptors)
            } else {
                return DiscoverDescriptorsResponse(descriptors: result.descriptors)
            }
        }
    }

    private func checkSecurityList(securityList: SecurityList) throws {
        if let blocked = firstBlockedUuidInRequest(securityList: securityList) {
            throw BluetoothError.blocklisted(blocked)
        }
    }

    private func firstBlockedUuidInRequest(securityList: SecurityList) -> UUID? {
        if securityList.isBlocked(request.serviceUuid, in: .services) {
            return request.serviceUuid
        }
        if securityList.isBlocked(request.characteristicUuid, in: .characteristics) {
            return request.characteristicUuid
        }
        if let uuid = request.query.descriptorUuid, securityList.isBlocked(uuid, in: .descriptors) {
            return uuid
        }
        return nil
    }
}
