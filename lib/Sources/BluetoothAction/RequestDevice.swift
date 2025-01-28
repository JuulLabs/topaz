import Bluetooth
import BluetoothClient
import BluetoothMessage
import DevicePicker
import Foundation
import JsMessage

struct RequestDeviceRequest: JsMessageDecodable {
    let options: Options?

    static func decode(from data: [String: JsType]?) throws -> Self? {
        let optionsData = data?["options"]?.dictionary
        return .init(options: try .decode(from: optionsData))
    }
}

struct RequestDeviceResponse: JsMessageEncodable {
    let peripheralId: UUID
    let name: JsConvertable?

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body([
            "uuid": peripheralId.uuidString,
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
        guard let selector else {
            throw BluetoothError.unavailable
        }
        let task = Task {
            let scanner = await client.scan(options: request.options)
            defer { scanner.cancel() }
            for await event in scanner.advertisements {
                try Task.checkCancellation()
                await selector.showAdvertisement(peripheral: event.peripheral, advertisement: event.advertisement)
            }
        }
        let peripheral = try await selector.awaitSelection().get()
        task.cancel()
        await state.putPeripheral(peripheral)
        return RequestDeviceResponse(peripheralId: peripheral.id, name: peripheral.name)
    }
}
