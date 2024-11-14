import Bluetooth
import BluetoothClient
import DevicePicker
import Effector
import Foundation
import JsMessage

struct RequestDeviceRequest: JsMessageDecodable {
    let filter: Filter

    static func decode(from data: [String: JsType]?) -> Self? {
        return .init(filter: .decode(from: data))
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
    let request: RequestDeviceRequest
    let selector: InteractiveDeviceSelector?
    let client: RequestClient?

    init(request: RequestDeviceRequest) {
        self.init(request: request, selector: nil, client: nil)
    }

    // TODO: remove this in favor of a rigorous DI system
    init(request: Request, selector: InteractiveDeviceSelector?, client: RequestClient?) {
        self.request = request
        self.selector = selector
        self.client = client
    }

    func execute(state: BluetoothState, effector: Effector) async throws -> RequestDeviceResponse {
        guard let client, let selector else {
            throw BluetoothError.unavailable
        }
        try await effector.bluetoothReadyState()
        let scanTask = effector.scan(filter: request.filter, client: client) { effect in
            await selector.showAdvertisement(peripheral: effect.peripheral, advertisement: effect.advertisement)
        }
        defer { scanTask.cancel() }
        let peripheral = try await selector.awaitSelection().get()
        await state.putPeripheral(peripheral)
        return RequestDeviceResponse(peripheralId: peripheral.identifier, name: peripheral.name)
    }
}

fileprivate extension Effector {
    func scan(
        filter: Filter,
        client: RequestClient,
        onAdvertisement: @escaping @Sendable (AdvertisementEffect) async -> Void
    ) -> Task<(), any Error> {
        Task {
            client.startScanning(filter)
            defer { client.stopScanning() }
            var failure: Error?
            while failure == nil && !Task.isCancelled {
                do {
                    let result = try await self.advertisement()
                    await onAdvertisement(result)
                } catch {
                    failure = error
                    break
                }
            }
            // TODO: handle error condition
        }
    }
}
