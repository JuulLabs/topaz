import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct GetDevicesRequest: JsMessageDecodable {
    static func decode(from data: [String: JsType]?) -> Self? {
        return .init()
    }
}

struct GetDevicesResponse: JsMessageEncodable {
    let peripherals: [(id: UUID, name: JsConvertable?)]

    func toJsMessage() -> JsMessageResponse {
        .body(
            peripherals.map { (id, name) in
                [
                    "uuid": id.uuidString,
                    "name": name,
                ]
            }
        )
    }
}

struct GetDevices: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: GetDevicesRequest

    init(request: GetDevicesRequest) {
        self.request = request
    }

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> GetDevicesResponse {
        let uuids = await state.getKnownPeripheralIdentifiers()
        let peripherals = await client.getPeripherals(withIdentifiers: uuids)
        return GetDevicesResponse(peripherals: peripherals.map { peripheral in
            (id: peripheral.id, name: peripheral.name)
        })
    }
}
