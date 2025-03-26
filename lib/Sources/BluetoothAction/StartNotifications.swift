import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct StartNotifications: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest

    init(request: CharacteristicRequest) {
        self.request = request
    }

    func execute(state: BluetoothState, client: any BluetoothClient) async throws -> CharacteristicResponse {
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)

        guard characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) else {
            throw BluetoothError.characteristicNotificationsNotSupported(characteristic: request.characteristicUuid)
        }
        guard characteristic.isNotifying == false else {
            return CharacteristicResponse()
        }

        _ = try await client.characteristicSetNotifications(peripheral, service: service, characteristic: characteristic, enable: true)

        return CharacteristicResponse()
    }
}
