import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList

struct ReadDescriptorRequest: JsMessageDecodable {
    let peripheralId: UUID
    let serviceUuid: UUID
    let characteristicUuid: UUID
    let instance: UInt32
    let descriptorUuid: UUID

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
        guard let descriptor = data?["descriptor"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        return .init(peripheralId: device, serviceUuid: service, characteristicUuid: characteristic, instance: instance, descriptorUuid: descriptor)
    }
}

struct ReadDescriptorResponse: JsMessageEncodable {
    let data: Data

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body(data)
    }
}

struct ReadDescriptor: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: ReadDescriptorRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> ReadDescriptorResponse {
        try await checkSecurityList(securityList: state.securityList)
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (_, characteristic) = try await state.getCharacteristic(
            peripheralId: request.peripheralId,
            serviceId: request.serviceUuid,
            characteristicId: request.characteristicUuid,
            instance: request.instance
        )
        let descriptor = try characteristic.getDescriptor(request.descriptorUuid)
        let event: DescriptorChangedEvent = try await eventBus.awaitEvent(
            forKey: .descriptor(
                .descriptorValue,
                peripheralId: peripheral.id,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance,
                descriptorId: descriptor.uuid
            )
        ) {
            client.readDescriptor(peripheral: peripheral, descriptor: descriptor)
        }
        return ReadDescriptorResponse(data: event.data)
    }

    private func checkSecurityList(securityList: SecurityList) throws {
        if securityList.isBlocked(request.descriptorUuid, in: .descriptors, for: .reading) {
            throw BluetoothError.blocklisted(request.descriptorUuid)
        }
    }
}
