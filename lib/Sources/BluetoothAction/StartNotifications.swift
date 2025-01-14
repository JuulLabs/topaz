import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct StartNotifications: BluetoothAction {

    var requiresReadyState: Bool = false // ?
    let request: CharacteristicRequest

    init(request: CharacteristicRequest) {
        self.request = request
    }

    /*
     If this.uuid is blocklisted for reads, reject promise with a SecurityError and abort these steps.

     DONE If this.service.device.gatt.connected is false, reject promise with a NetworkError and abort these steps.

     DONE Let characteristic be this.[[representedCharacteristic]].

     GET FOR FREE If characteristic is null, return a promise rejected with an InvalidStateError and abort these steps.

     DONE If neither of the Notify or Indicate bits are set in characteristic’s properties, reject promise with a NotSupportedError and abort these steps.

     DONE If characteristic’s active notification context set contains navigator.bluetooth, resolve promise with this and abort these steps.

     If the UA is currently using the Bluetooth system, it MAY reject promise with a NetworkError and abort these steps.

      Implementations may be able to avoid this NetworkError, but for now sites need to serialize their use of this API and/or give the user a way to retry failed operations. [Issue #188]

     If the characteristic has a Client Characteristic Configuration descriptor, use any of the Characteristic Descriptors procedures to ensure that one of the Notification or Indication bits in characteristic’s Client Characteristic Configuration descriptor is set, matching the constraints in characteristic’s properties. The UA SHOULD avoid setting both bits, and MUST deduplicate value-change events if both bits are set. Handle errors as described in § 6.7 Error handling.

     Note: Some devices have characteristics whose properties include the Notify or Indicate bit but that don’t have a Client Characteristic Configuration descriptor. These non-standard-compliant characteristics tend to send notifications or indications unconditionally, so this specification allows applications to simply subscribe to their messages.
     If the previous step returned an error, reject promise with that error and abort these steps.

     Add navigator.bluetooth to characteristic’s active notification context set.

     Resolve promise with this.
     */

    func execute(state: BluetoothMessage.BluetoothState, client: any BluetoothClient) async throws -> CharacteristicResponse {

        let peripheral = try await state.getPeripheral(request.peripheralId)
        let characteristic = try await state.getCharacteristic(peripheralId: request.peripheralId, serviceId: request.serviceUuid, characteristicId: request.characteristicUuid)

//        characteristic.properties.contains(.notify)

        guard peripheral.connectionState == .connected else {
            throw BluetoothError.deviceNotConnected
        }

        guard characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) else {
            throw BluetoothError.notSupported
        }

        guard characteristic.isNotifying == false else {
            return CharacteristicResponse()
        }

//        let service = try await state.getService(peripheralId: request.peripheralId, serviceId: request.serviceUuid)
//        service.

        _ = try await client.startNotifications(peripheral, characteristic: characteristic)

        return CharacteristicResponse()
    }
}
