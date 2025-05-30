import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage

struct ForgetDeviceRequest: JsMessageDecodable {
    let peripheralId: UUID

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        return .init(peripheralId: uuid)
    }
}

struct ForgetDeviceResponse: JsMessageEncodable {
    func toJsMessage() -> JsMessageResponse {
        .body([:])
    }
}

struct ForgetDevice: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: ForgetDeviceRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> ForgetDeviceResponse {
        await state.forgetPeripheral(identifier: request.peripheralId)
        return ForgetDeviceResponse()
    }
}
