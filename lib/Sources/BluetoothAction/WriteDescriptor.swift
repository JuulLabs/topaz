import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct WriteDescriptorRequest: JsMessageDecodable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let characteristicInstance: UInt32
    let descriptorUuid: UUID
    let value: Data

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
        guard let descriptor = data?["descriptor"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        guard let value = data?["value"]?.data else {
            return nil
        }
        return .init(
            peripheralId: device,
            serviceUuid: service,
            characteristicUuid: characteristic,
            characteristicInstance: instance,
            descriptorUuid: descriptor,
            value: value
        )
    }
}

// Response is unused on JavaScript side but needed to have `ReadDescriptor` conform to `BluetoothAction`.
struct DescriptorResponse: JsMessageEncodable {
    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body([:])
    }
}

struct WriteDescriptor: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: WriteDescriptorRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> DescriptorResponse {
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let characteristic = try await state.getCharacteristic(
            peripheralId: request.peripheralId,
            serviceId: request.serviceUuid,
            characteristicId: request.characteristicUuid,
            instance: request.characteristicInstance
        )
        let descriptor = try characteristic.getDescriptor(request.descriptorUuid)
        _ = try await client.descriptorWrite(peripheral, characteristic: characteristic, descriptor: descriptor, value: request.value)
        return DescriptorResponse()
    }
}
