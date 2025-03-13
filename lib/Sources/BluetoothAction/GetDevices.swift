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
                    "uuid": id,
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
        let knownUuids = await state.getKnownPeripheralIdentifiers()
        let peripherals = await client.getPeripherals(withIdentifiers: Array(knownUuids))

        // As a side effect, execute should remove any known peripheral identifiers that could not
        // be returned by client from persistence
        await state.forgetPeripherals(identifiers: Array(knownUuids.subtracting(peripherals.map { $0.id })))

        return GetDevicesResponse(peripherals: peripherals.map { peripheral in
            (id: peripheral.id, name: peripheral.name)
        })
    }
}
