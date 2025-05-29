import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList

struct StartNotifications: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> CharacteristicResponse {
        try await checkSecurityList(securityList: state.securityList)
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(
            peripheralId: request.peripheralId,
            serviceId: request.serviceUuid,
            characteristicId: request.characteristicUuid,
            instance: request.characteristicInstance
        )

        guard characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) else {
            throw BluetoothError.characteristicNotificationsNotSupported(characteristic: request.characteristicUuid)
        }
        guard characteristic.isNotifying == false else {
            return CharacteristicResponse()
        }

        let _: CharacteristicEvent = try await eventBus.awaitEvent(
            forKey: .characteristic(
                .characteristicNotify,
                peripheralId: peripheral.id,
                serviceId: service.uuid,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance
            )
        ) {
            client.setNotify(peripheral: peripheral, characteristic: characteristic, value: true)
        }
        return CharacteristicResponse()
    }

    private func checkSecurityList(securityList: SecurityList) throws {
        if securityList.isBlocked(request.characteristicUuid, in: .characteristics, for: .reading) {
            throw BluetoothError.blocklisted(request.characteristicUuid)
        }
    }
}
