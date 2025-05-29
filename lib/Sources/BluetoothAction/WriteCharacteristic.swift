import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList

struct WriteCharacteristicRequest: JsMessageDecodable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let characteristicInstance: UInt32
    let value: Data
    let withResponse: Bool

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
        guard let value = data?["value"]?.data else {
            return nil
        }
        guard let withResponse = data?["withResponse"]?.number?.boolValue else {
            return nil
        }
        return .init(
            peripheralId: device,
            serviceUuid: service,
            characteristicUuid: characteristic,
            characteristicInstance: instance,
            value: value,
            withResponse: withResponse
        )
    }
}

/**
 An action that writes a value to a characteristic, with or without a response.

 Please note we must disambiguate the word "response" in this context. It does not refer to the application
 layer concept of write-request-for-response, but instead controls whether or not the write operation itself
 is guaranteed to have been completed.

 When we write-with-response, the call blocks until after confirmation that the write operation was complete.

 In contrast, write-without-response is a fire-and-forget operation that returns immediately. It is guarded
 by waiting until the device is in a ready-to-send state, but there is no guarantee it will succeed.

 In either case, the promise resolves with an empty object. If the write does in fact pertain to an application
 level request for some data from the device, that data will be emitted via a `characteristicvaluechanged` event.
 */
struct WriteCharacteristic: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: WriteCharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> CharacteristicResponse {
        try await checkSecurityList(securityList: state.securityList)
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(
            peripheralId: request.peripheralId,
            serviceId: request.serviceUuid,
            characteristicId: request.characteristicUuid,
            instance: request.characteristicInstance
        )
        if request.withResponse {
            // Perform the write operation immediately, and then wait until we receive confirmation that the write was completed
            let _: CharacteristicEvent = try await eventBus.awaitEvent(
                forKey: .characteristic(
                    .characteristicWrite,
                    peripheralId: peripheral.id,
                    serviceId: service.uuid,
                    characteristicId: characteristic.uuid,
                    instance: characteristic.instance
                )
            ) {
                client.writeCharacteristic(peripheral: peripheral, characteristic: characteristic, value: request.value, withResponse: true)
            }
        } else {
            // Perform the write operation only after the peripheral is ready to send, and do not wait for a response
            let readyPeripheral = try await eventBus.waitForReadyToSend(peripheral: peripheral)
            client.writeCharacteristic(peripheral: readyPeripheral, characteristic: characteristic, value: request.value, withResponse: false)
        }
        return CharacteristicResponse()
    }

    private func checkSecurityList(securityList: SecurityList) throws {
        if securityList.isBlocked(request.characteristicUuid, in: .characteristics, for: .writing) {
            throw BluetoothError.blocklisted(request.characteristicUuid)
        }
    }
}

private extension EventBus {
    func waitForReadyToSend(peripheral: Peripheral) async throws -> Peripheral {
        if peripheral.isReadyToSendWriteWithoutResponse {
            return peripheral
        }
        let event: PeripheralEvent = try await awaitEvent(
            forKey: .peripheral(.canSendWriteWithoutResponse, peripheral)
        ) {
            $0.peripheral.isReadyToSendWriteWithoutResponse
        }
        return event.peripheral
    }
}
