import Bluetooth
import Foundation
import JsMessage

struct ConnectRequest {
    let peripheralId: UUID
}

struct ConnectResponse {
    let isConnected: Bool = true
}

struct Connector {
    let request: ConnectRequest

    func execute(state: BluetoothState, effector: Effector) async throws -> ConnectResponse {
        try await effector.bluetoothReadyState()
        let peripheral = try await state.getPeripheral(request.peripheralId)
        if case .connected = peripheral.connectionState {
            return ConnectResponse()
        }
        try await effector.connect(peripheral)
        return ConnectResponse()
    }
}
