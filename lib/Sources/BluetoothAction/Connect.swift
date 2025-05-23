import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage

struct ConnectRequest: JsMessageDecodable {
    let peripheralId: UUID

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        return .init(peripheralId: uuid)
    }
}

struct ConnectResponse: JsMessageEncodable {
    let isConnected: Bool = true

    func toJsMessage() -> JsMessageResponse {
        return .body(["connected": isConnected])
    }
}

struct Connector: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: ConnectRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> ConnectResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        if case .connected = peripheral.connectionState {
            return ConnectResponse()
        }
        await state.rememberPeripheral(identifier: peripheral.id)
        let _: PeripheralEvent = try await eventBus.awaitEvent(forKey: .peripheral(.connect, peripheral)) {
            client.connect(peripheral: peripheral)
        }
        return ConnectResponse()
    }
}
