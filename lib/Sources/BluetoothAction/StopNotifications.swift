import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage

struct StopNotifications: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> CharacteristicResponse {
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)
        let _: CharacteristicEvent = try await eventBus.awaitEvent(
            forKey: .characteristic(
                .characteristicNotify,
                peripheralId: peripheral.id,
                serviceId: service.uuid,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance
            )
        ) {
            client.setNotify(peripheral: peripheral, characteristic: characteristic, value: false)
        }
        return CharacteristicResponse()
    }
}
