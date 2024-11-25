import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct DiscoverServicesRequest: JsMessageDecodable {
    let peripheralId: UUID
    let query: Query

    var filter: ServiceDiscoveryFilter {
        let services = query.serviceUuid.map { [$0] }
        return ServiceDiscoveryFilter(primaryOnly: true, services: services)
    }

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
            "services": services.map { $0.uuid }
        ])
    }
}

struct DiscoverServices: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: DiscoverServicesRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> DiscoverServicesResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        // todo: error response if not connected
        let result = try await client.discoverServices(peripheral, filter: request.filter)
        await state.setServices(result.services, on: peripheral.id)
        let primaryServices = result.services.filter { $0.isPrimary }
        switch request.query {
        case let .first(serviceUuid):
            guard let service = primaryServices.first else {
                throw BluetoothError.noSuchService(serviceUuid)
            }
            return DiscoverServicesResponse(peripheralId: peripheral.id, services: [service])
        case .all:
            return DiscoverServicesResponse(peripheralId: peripheral.id, services: primaryServices)
        }
    }
}
