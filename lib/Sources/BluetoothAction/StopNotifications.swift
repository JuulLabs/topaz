import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct StopNotifications: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest

    init(request: CharacteristicRequest) {
        self.request = request
    }

    func execute(state: BluetoothState, client: any BluetoothClient) async throws -> CharacteristicResponse {
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)
        _ = try await client.characteristicSetNotifications(peripheral, service: service, characteristic: characteristic, enable: false)
        return CharacteristicResponse()
    }
}
