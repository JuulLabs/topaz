import Bluetooth
import BluetoothClient
import BluetoothMessage
import DevicePicker
import EventBus
import Foundation
import JsMessage
import SecurityList

struct RequestDeviceRequest: JsMessageDecodable {
    let rawOptionsData: [String: JsType]?

    static func decode(from data: [String: JsType]?) -> Self? {
        return .init(rawOptionsData: data?["options"]?.dictionary)
    }

    func decodeAndValidateOptions() throws -> Options {
        try .decode(from: rawOptionsData)
    }
}

struct RequestDeviceResponse: JsMessageEncodable {
    let peripheralId: UUID
    let name: JsConvertable?

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body([
            "uuid": peripheralId,
            "name": name,
        ])
    }
}

struct RequestDevice: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: RequestDeviceRequest
    let selector: InteractiveDeviceSelector?

    init(request: RequestDeviceRequest) {
        self.init(request: request, selector: nil)
    }

    // TODO: remove this in favor of a rigorous DI system
    init(request: RequestDeviceRequest, selector: InteractiveDeviceSelector?) {
        self.request = request
        self.selector = selector
    }

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> RequestDeviceResponse {
        let options = try request.decodeAndValidateOptions()
        try await checkSecurityList(securityList: state.securityList, options: options)
        guard let selector else {
            throw BluetoothError.unavailable
        }

        await eventBus.attachEventListener(forKey: .advertisement) { (result: Result<AdvertisementEvent, any Error>) in
            guard case let .success(event) = result else { return }
            guard options.includeAdvertisementEventInDeviceList(event) else { return }
            await selector.showAdvertisement(peripheral: event.peripheral, advertisement: event.advertisement)
        }
        client.startScanning(serviceUuids: options.allServiceUuids())
        let selection = await selector.awaitSelection()
        client.stopScanning()
        await eventBus.detachListener(forKey: EventRegistrationKey.advertisement)

        var peripheral = try selection.get()
        peripheral.permissions = options.toRestrictivePermissions()
        await state.putPeripheral(peripheral, replace: true)
        return RequestDeviceResponse(peripheralId: peripheral.id, name: peripheral.name)
    }

    private func checkSecurityList(securityList: SecurityList, options: Options) throws {
        guard let filters = options.filters else { return }
        try checkFiltersAreAllowed(securityList: securityList, filters: filters)
    }
}
