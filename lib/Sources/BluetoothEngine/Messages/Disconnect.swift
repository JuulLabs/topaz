import Bluetooth
import Effector
import Foundation
import JsMessage

struct DisconnectRequest: JsMessageDecodable, PeripheralIdentifiable {
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

struct DisconnectEvent: JsEventEncodable {
    let peripheralId: UUID

    func toJsEvent() -> JsEvent {
        JsEvent(targetId: peripheralId.uuidString, eventName: "gattserverdisconnected")
    }
}

struct Disconnector: BluetoothAction {
    let request: DisconnectRequest

    func execute(state: BluetoothState, effector: Effector) async throws -> DisconnectResponse {
        try await effector.bluetoothReadyState()
        let peripheral = try await state.getPeripheral(request.peripheralId)
        if case .disconnected = peripheral.connectionState {
            return DisconnectResponse(peripheralId: peripheral.identifier)
        }
        _ = try await effector.disconnect(peripheral)
        return DisconnectResponse(peripheralId: peripheral.identifier)
    }
}
