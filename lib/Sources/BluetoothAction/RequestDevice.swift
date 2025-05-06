import Bluetooth
import BluetoothClient
import BluetoothMessage
import DevicePicker
import Foundation
import JsMessage
import SecurityList

struct RequestDeviceRequest: JsMessageDecodable {
    private let rawOptionsData: [String: JsType]?

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

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> RequestDeviceResponse {
        let options = try request.decodeAndValidateOptions()
        try await checkSecurityList(securityList: state.securityList, options: options)
        guard let selector else {
            throw BluetoothError.unavailable
        }
        let task = Task {
            let scanner = await client.scan(options: options)
            defer { scanner.cancel() }
            for await event in scanner.advertisements {
                try Task.checkCancellation()
                await selector.showAdvertisement(peripheral: event.peripheral, advertisement: event.advertisement)
            }
        }
        let peripheral = try await selector.awaitSelection().get()
        task.cancel()
        await state.putPeripheral(peripheral, replace: true)
        return RequestDeviceResponse(peripheralId: peripheral.id, name: peripheral.name)
    }

    private func checkSecurityList(securityList: SecurityList, options: Options) throws {
        guard let filters = options.filters else { return }
        try checkFiltersAreAllowed(securityList: securityList, filters: filters)
    }
}
