import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct ReadCharacteristic: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> CharacteristicResponse {
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)
        // The Js characteristic object's `value` is mutated via an event that is triggered by the read
        // So we ignore the result here and over on the Js side the updated value gets read from the characteristic directly
        _ = try await client.characteristicRead(peripheral, service: service, characteristic: characteristic)
        return CharacteristicResponse()
    }
}

extension CharacteristicChangedEvent {
    func characteristicValueChangedEvent() -> JsEvent {
        let body: [String: JsConvertable] = [
            "device": peripheralId,
            "service": serviceId,
            "characteristic": characteristicId,
            "instance": instance,
            "value": data ?? jsNull,
        ]
        return JsEvent(targetId: characteristicId.uuidString.lowercased(), eventName: "characteristicvaluechanged", body: body)
    }
}
