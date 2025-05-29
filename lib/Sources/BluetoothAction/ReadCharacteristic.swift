import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList

struct ReadCharacteristic: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: CharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> CharacteristicResponse {
        try await checkSecurityList(securityList: state.securityList)
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid, instance: request.characteristicInstance)
        // The engine propagates all characteristic change events to javascript automatically because they can happen at any time,
        // not only because we requested a read. Those events mutate the Js characteristic object's `value` property directly.
        // So we ignore the result here and over on the Js side the updated value will be read from the characteristic object.
        let _: CharacteristicChangedEvent = try await eventBus.awaitEvent(
            forKey: .characteristic(
                .characteristicValue,
                peripheralId: peripheral.id,
                serviceId: service.uuid,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance
            )
        ) {
            client.readCharacteristic(peripheral: peripheral, characteristic: characteristic)
        }
        return CharacteristicResponse()
    }

    private func checkSecurityList(securityList: SecurityList) throws {
        if securityList.isBlocked(request.characteristicUuid, in: .characteristics, for: .reading) {
            throw BluetoothError.blocklisted(request.characteristicUuid)
        }
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
