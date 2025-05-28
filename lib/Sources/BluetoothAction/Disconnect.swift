import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
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
    let isDisconnected: Bool = true

    func toJsMessage() -> JsMessage.JsMessageResponse {
        return .body(["disconnected": isDisconnected])
    }
}

struct Disconnector: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: DisconnectRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> DisconnectResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        if case .disconnected = peripheral.connectionState {
            return DisconnectResponse()
        }
        let _: DisconnectionEvent = try await eventBus.awaitEvent(forKey: .peripheral(.disconnect, peripheral)) {
            client.disconnect(peripheral: peripheral)
        }
        return DisconnectResponse()
    }
}

extension DisconnectionEvent {
    public func gattServerDisconnectedEvent() -> JsEvent {
        let (peripheralId, reason) =
        switch self {
        case let .requested(peripheral):
            (peripheral.id, "disconnected")
        case let .unexpected(peripheral, cause):
            (peripheral.id, cause.localizedDescription)
        }
        return JsEvent(
            targetId: peripheralId.uuidString.lowercased(),
            eventName: "gattserverdisconnected",
            body: ["reason": reason]
        )
    }
}
