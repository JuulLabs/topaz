import Bluetooth
import BluetoothClient
import BluetoothMessage
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

struct WriteCharacteristic: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: WriteCharacteristicRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> CharacteristicResponse {
        try await checkSecurityList(securityList: state.securityList)
        let peripheral = try await state.getConnectedPeripheral(request.peripheralId)
        let (service, characteristic) = try await state.getCharacteristic(
            peripheralId: request.peripheralId,
            serviceId: request.serviceUuid,
            characteristicId: request.characteristicUuid,
            instance: request.characteristicInstance
        )
        if !request.withResponse {
            // Update the peripheral state with the latest value read from the actual live CBPeripheral object
            try await state.refreshCanSendWriteWithoutResponse(request.peripheralId)
            while try await !state.getCanSendWriteWithoutResponse(request.peripheralId) {
                // The peripheral state is false, waiting until the delegate callback updates it to true...
            }
        }
        _ = try await client.characteristicWrite(peripheral, service: service, characteristic: characteristic, value: request.value, withResponse: request.withResponse)
        return CharacteristicResponse()
    }

    private func checkSecurityList(securityList: SecurityList) throws {
        if securityList.isBlocked(request.characteristicUuid, in: .characteristics, for: .writing) {
            throw BluetoothError.blocklisted(request.characteristicUuid)
        }
    }
}
