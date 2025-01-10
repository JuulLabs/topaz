import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage


// implement a JSMessageDecodable
struct CharacteristicRequest: JsMessageDecodable {

    //
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let characteristicInstance: UInt32

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
        return .init(peripheralId: device, serviceUuid: service, characteristicUuid: characteristic, characteristicInstance: instance)
    }
}

// Response is unused on JavaScript side but needed to have `ReadCharacteristic` conform to `BluetoothAction`.
struct CharacteristicResponse: JsMessageEncodable {
    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body([:])
    }
}

struct ReadCharacteristic: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest


    // this is the meat and potatoes
    func execute(state: BluetoothState, client: BluetoothClient) async throws -> CharacteristicResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        // todo: error response if not connected
        let characteristic = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid)
        // The Js characteristic object's `value` is mutated via an event that is triggered by the read
        // So we ignore the result here and over on the Js side the updated value gets read from the characteristic directly
        _ = try await client.characteristicRead(peripheral, characteristic: characteristic)
        return CharacteristicResponse()
    }
}

extension CharacteristicChangedEvent {
    public func characteristicValueChangedEvent() -> JsEvent {
        JsEvent(targetId: characteristicKey(uuid: characteristicId, instance: instance), eventName: "characteristicvaluechanged", body: data)
    }
}

private func characteristicKey(uuid: UUID, instance: UInt32) -> String {
    "\(uuid.uuidString.lowercased()).\(instance)"
}
