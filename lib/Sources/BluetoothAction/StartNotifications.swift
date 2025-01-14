import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct StartNotifications: BluetoothAction {

    var requiresReadyState: Bool = true
    let request: CharacteristicRequest

    init(request: CharacteristicRequest) {
        self.request = request
    }

    func execute(state: BluetoothMessage.BluetoothState, client: any BluetoothClient) async throws -> CharacteristicResponse {
        let peripheral = try await state.getPeripheral(request.peripheralId)
        let characteristic = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)

        guard peripheral.connectionState == .connected else {
            throw BluetoothError.deviceNotConnected
        }

        guard characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) else {
            throw BluetoothError.notSupported
        }

        guard characteristic.isNotifying == false else {
            return CharacteristicResponse()
        }

        _ = try await client.startNotifications(peripheral, characteristic: characteristic)

        return CharacteristicResponse()
    }
}
