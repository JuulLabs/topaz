import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

//struct StopNotificationsRequest: JsMessageDecodable {
//
//    //
//    let peripheralId: UUID
//    let serviceUuid: UUID
//    let characteristicUuid: UUID
//
//    static func decode(from data: [String: JsType]?) -> Self? {
//        guard let device = data?["device"]?.string.flatMap(UUID.init(uuidString:)) else {
//            return nil
//        }
//        guard let service = data?["service"]?.string.flatMap(UUID.init(uuidString:)) else {
//            return nil
//        }
//        guard let characteristic = data?["characteristic"]?.string.flatMap(UUID.init(uuidString:)) else {
//            return nil
//        }
//        return .init(peripheralId: device, serviceUuid: service, characteristicUuid: characteristic)
//    }
//}
//
//struct StopNotificationsResponse: JsMessageEncodable {
//    func toJsMessage() -> JsMessage.JsMessageResponse {
//        .body([:])
//    }
//}

struct StopNotifications: BluetoothAction {

//    typealias Request = StartNotificationsRequest

//    typealias Response = StartNotificationsResponse

    var requiresReadyState: Bool = false // ?

    let request: CharacteristicRequest

    init(request: CharacteristicRequest) {
        self.request = request
    }

    func execute(state: BluetoothMessage.BluetoothState, client: any BluetoothClient) async throws -> CharacteristicResponse {

        let peripheral  = try await state.getPeripheral(request.peripheralId)
        let characteristic = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid)
        _ = try await client.stopNotify(peripheral, characteristic: characteristic)

        return CharacteristicResponse()

//        let peripheral = try await state.getPeripheral(request.peripheralId)
//        // todo: error response if not connected
//        let characteristic = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid)
//        // The Js characteristic object's `value` is mutated via an event that is triggered by the read
//        // So we ignore the result here and over on the Js side the updated value gets read from the characteristic directly
//        _ = try await client.characteristicRead(peripheral, characteristic: characteristic)
//        return ReadCharacteristicResponse()
    }

}
