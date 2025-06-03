import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList

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

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> DiscoverServicesResponse {
        let securityList = await state.securityList
        try checkSecurityList(securityList: securityList)
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let result: ServiceDiscoveryEvent = try await eventBus.awaitEvent(
            forKey: .serviceDiscovery(peripheralId: peripheral.id)
        ) {
            client.discoverServices(peripheral: peripheral, uuids: request.filter.services)
        }
        let services = result.services.filter {
            !securityList.isBlocked($0.uuid, in: .services)
        }
        await state.setServices(services, on: peripheral.id)
        let primaryServices = services.filter { $0.isPrimary }
        switch request.query {
        case let .first(serviceUuid):
            guard isQueryAllowed(for: serviceUuid, in: peripheral.permissions) else {
                throw BluetoothError.accessToServiceDenied(serviceUuid)
            }
            // Already filtered during discovery, return the first one:
            guard let service = primaryServices.first else {
                throw BluetoothError.noSuchService(serviceUuid)
            }
            return DiscoverServicesResponse(services: [service])
        case let .all(.some(serviceUuid)):
            guard isQueryAllowed(for: serviceUuid, in: peripheral.permissions) else {
                throw BluetoothError.accessToServiceDenied(serviceUuid)
            }
            // Already filtered during discovery, return all of them:
            return DiscoverServicesResponse(services: primaryServices)
        case .all(.none):
            // Not yet filtered, only provide services that are in the allow list:
            let allowedServices = filterForAllowed(services: primaryServices, permissions: peripheral.permissions)
            return DiscoverServicesResponse(services: allowedServices)
        }
    }

    private func checkSecurityList(securityList: SecurityList) throws {
        if let uuid = request.query.serviceUuid, securityList.isBlocked(uuid, in: .services) {
            throw BluetoothError.blocklisted(uuid)
        }
    }

    private func isQueryAllowed(for uuid: UUID, in permissions: PeripheralPermissions) -> Bool {
        switch permissions.allowedServices {
        case .all:
            true
        case let .restricted(grantedUids):
            grantedUids.contains(uuid)
        }
    }

    private func filterForAllowed(services: [Service], permissions: PeripheralPermissions) -> [Service] {
        switch permissions.allowedServices {
        case .all:
            services
        case let .restricted(grantedUids):
            services.filter { service in
                grantedUids.contains(service.uuid)
            }
        }
    }
}
