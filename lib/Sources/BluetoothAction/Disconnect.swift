import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct DisconnectRequest: JsMessageDecodable {
    let peripheralId: UUID

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        return .init(peripheralId: uuid)
    }
}

struct DisconnectResponse: JsMessageEncodable {
    let peripheralId: UUID
    let isDisconnected: Bool = true

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body(["disconnected": isDisconnected])
    }
}

struct Disconnector: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: DisconnectRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> DisconnectResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        if case .disconnected = peripheral.connectionState {
            return DisconnectResponse(peripheralId: peripheral.id)
        }
        _ = try await client.disconnect(peripheral)
        return DisconnectResponse(peripheralId: peripheral.id)
    }
}

extension PeripheralEvent {
    public func gattServerDisconnectedEvent() -> JsEvent {
        JsEvent(targetId: peripheral.id.uuidString.lowercased(), eventName: "gattserverdisconnected")
    }
}
