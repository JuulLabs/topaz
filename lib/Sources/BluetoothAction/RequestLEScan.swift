import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList

struct RequestLEScanOptions: JsMessageDecodable {
    private let rawFilters: [JsType]
    let acceptAllAdvertisements: Bool
    let keepRepeatedDevices: Bool

    static func decode(from data: [String: JsType]?) -> Self? {
        let options = data?["options"]?.dictionary
        let rawFilters = options?["filters"]?.array ?? []
        let acceptAllAdvertisements = options?["acceptAllAdvertisements"]?.number?.boolValue ?? false
        let keepRepeatedDevices = options?["keepRepeatedDevices"]?.number?.boolValue ?? false
        return .init(rawFilters: rawFilters, acceptAllAdvertisements: acceptAllAdvertisements, keepRepeatedDevices: keepRepeatedDevices)
    }

    func decodeAndValidateFilters() throws -> [Options.Filter] {
        let filters = try rawFilters.compactMap { try Options.Filter.decode(from: $0.dictionary) }
        if acceptAllAdvertisements && !filters.isEmpty {
            throw OptionsError.invalidInput("Cannot set acceptAllAdvertisements to true if filters are provided")
        }
        if !acceptAllAdvertisements && filters.isEmpty {
            throw OptionsError.invalidInput("Cannot set acceptAllAdvertisements to false without providing filters")
        }
        return filters
    }
}

enum RequestLEScanRequest: JsMessageDecodable {
    case start(options: RequestLEScanOptions)
    case stop(id: String)

    static func decode(from data: [String: JsType]?) -> Self? {
        if data?["stop"]?.number?.boolValue == true {
            guard let scanId = data?["scanId"]?.string else { return nil }
            return .stop(id: scanId)
        }
        return RequestLEScanOptions.decode(from: data).map { .start(options: $0) }
    }
}

enum RequestLEScanResponse: JsMessageEncodable {
    case start(id: String, scan: BluetoothLEScan)
    case stop

    func toJsMessage() -> JsMessage.JsMessageResponse {
        switch self {
        case let .start(id, scan):
            .body([
                "scanId": id,
                "active": scan.active,
                "acceptAllAdvertisements": scan.acceptAllAdvertisements,
                "keepRepeatedDevices": scan.keepRepeatedDevices,
            ])
        case .stop:
            .body([
                "active": false,
            ])
        }
    }
}

struct RequestLEScan: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: RequestLEScanRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> RequestLEScanResponse {
        switch request {
        case let .start(options):
            try await executeStart(state: state, client: client, eventBus: eventBus, options: options)
        case let .stop(scanId):
            try await executeStop(client: client, eventBus: eventBus, scanId: scanId)
        }
    }

    private func executeStart(
        state: BluetoothState,
        client: BluetoothClient,
        eventBus: EventBus,
        options: RequestLEScanOptions
    ) async throws -> RequestLEScanResponse {
        let scanId = UUID().uuidString
        let filters = try options.decodeAndValidateFilters()
        try await checkFiltersAreAllowed(securityList: state.securityList, filters: filters)
        let activeScan = BluetoothLEScan(
            filters: filters,
            keepRepeatedDevices: options.keepRepeatedDevices,
            acceptAllAdvertisements: options.acceptAllAdvertisements,
            active: true
        )
        let options = activeScan.toFilterOptions()
        await eventBus.attachEventListener(forKey: .advertisement) { (result: Result<AdvertisementEvent, any Error>) in
            guard case let .success(event) = result else { return }
            guard options.includeAdvertisementEventInDeviceList(event) else { return }
            // TODO: Potential optimization: keep track of these devices and discard them if never connected after scanning
            await state.putPeripheral(event.peripheral, replace: false)
            // Scanning is unrestricted so clear any access permissions on the device here:
            await state.setPermissions(.init(allowedServices: .all), on: event.peripheral.id)
            await eventBus.sendJsEvent(event.toJs(targetId: "bluetooth"))
        }
        client.startScanning(serviceUuids: options.allServiceUuids())
        return .start(id: scanId, scan: activeScan)
    }

    private func executeStop(
        client: BluetoothClient,
        eventBus: EventBus,
        scanId: String
    ) async throws -> RequestLEScanResponse {
        client.stopScanning()
        await eventBus.detachListener(forKey: EventRegistrationKey.advertisement)
        return .stop
    }
}
