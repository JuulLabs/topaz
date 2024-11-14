import Bluetooth
import Foundation
import JsMessage

struct ConnectRequest: JsMessageDecodable, PeripheralIdentifiable {
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
    let request: ConnectRequest

    func execute(state: BluetoothState, effector: some BluetoothEffector) async throws -> ConnectResponse {
        try await effector.bluetoothReadyState()
        let peripheral = try await state.getPeripheral(request.peripheralId)
        if case .connected = peripheral.connectionState {
            return ConnectResponse()
        }
        try await effector.runEffect(action: .connect, uuid: peripheral.identifier) { client in
            client.connect(peripheral)
        }
        return ConnectResponse()
    }
}
