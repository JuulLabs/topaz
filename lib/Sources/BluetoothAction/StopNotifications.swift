import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct StopNotifications: BluetoothAction {

    var requiresReadyState: Bool = true
    let request: CharacteristicRequest

    init(request: CharacteristicRequest) {
        self.request = request
    }

    func execute(state: BluetoothMessage.BluetoothState, client: any BluetoothClient) async throws -> CharacteristicResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        let characteristic = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)
        _ = try await client.stopNotifications(peripheral, characteristic: characteristic)

        return CharacteristicResponse()
    }
}
