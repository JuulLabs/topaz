import Bluetooth
import Foundation
import JsMessage

struct ReadCharacteristicRequest: JsMessageDecodable, PeripheralIdentifiable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let characteristicInstance: UInt32

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let device = data?["device"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let service = data?["service"]?.string.flatMap(resolveServiceUuid) else {
            return nil
        }
        guard let characteristic = data?["characteristic"]?.string.flatMap(resolveCharacteristicUuid) else {
            return nil
        }
        guard let instance = data?["instance"]?.number?.uint32Value else {
            return nil
        }
        return .init(peripheralId: device, serviceUuid: service, characteristicUuid: characteristic, characteristicInstance: instance)
    }
}

// Unused but needed to have `ReadCharacteristic` conform to `BluetoothAction`.
struct ReadCharacteristicResponse: JsMessageEncodable {
    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body(jsNull)
    }
}

struct ReadCharacteristic: BluetoothAction {
    let request: ReadCharacteristicRequest

    func execute(state: BluetoothState, effector: some BluetoothEffector) async throws -> ReadCharacteristicResponse {
        try await effector.bluetoothReadyState()
        let peripheral = try await state.getPeripheral(request.peripheralId)
        // todo: error response if not connected
        try await effector.runEffect(action: .readCharacteristic, uuid: peripheral.identifier) { client in
            try client.readCharacteristic(peripheral, request.serviceUuid, request.characteristicUuid, request.characteristicInstance)
        }
        return ReadCharacteristicResponse()
    }
}
