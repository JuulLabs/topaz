import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct ReadCharacteristic: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> CharacteristicResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        // todo: error response if not connected
        let characteristic = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)
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
