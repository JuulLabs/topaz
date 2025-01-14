import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct WriteCharacteristicRequest: JsMessageDecodable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let characteristicInstance: UInt32
    let value: Data
    let withResponse: Bool

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let device = data?["device"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let service = data?["service"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let characteristic = data?["characteristic"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let instance = data?["instance"]?.number?.uint32Value else {
            return nil
        }
        guard let value = data?["value"]?.data else {
            return nil
        }
        guard let withResponse = data?["withResponse"]?.number?.boolValue else {
            return nil
        }
        return .init(
            peripheralId: device,
            serviceUuid: service,
            characteristicUuid: characteristic,
            characteristicInstance: instance,
            value: value,
            withResponse: withResponse
        )
    }
}

// Response is unused on JavaScript side but needed to have `WriteCharacteristic` conform to `BluetoothAction`.
struct WriteCharacteristicResponse: JsMessageEncodable {
    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body([:])
    }
}

struct WriteCharacteristic: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: WriteCharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> WriteCharacteristicResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        // todo: error response if not connected
        let characteristic = try await state.getCharacteristic(
            peripheralId: request.peripheralId,
            serviceId: request.serviceUuid,
            characteristicId: request.characteristicUuid,
            instance: request.characteristicInstance
        )
        _ = try await client.characteristicWrite(peripheral, characteristic: characteristic, value: request.value, withResponse: request.withResponse)
        return WriteCharacteristicResponse()
    }
}
