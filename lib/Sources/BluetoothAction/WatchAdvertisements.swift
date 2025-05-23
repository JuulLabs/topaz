import Bluetooth
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList

struct WatchAdvertisementsRequest: JsMessageDecodable {
    let enable: Bool
    let peripheralId: UUID

    static func decode(from data: [String: JsType]?) -> Self? {
        guard let enable = data?["enable"]?.number?.boolValue else {
            return nil
        }
        guard let uuid = data?["uuid"]?.string.flatMap(UUID.init(uuidString:)) else {
            return nil
        }
        return .init(enable: enable, peripheralId: uuid)
    }
}

struct WatchAdvertisementsResponse: JsMessageEncodable {
    func toJsMessage() -> JsMessageResponse {
        .body([:])
    }
}

struct WatchAdvertisements: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: WatchAdvertisementsRequest

    func execute(state: BluetoothState, client: BluetoothClient, eventBus: EventBus) async throws -> WatchAdvertisementsResponse {
        if request.enable {
            await executeStart(client: client, eventBus: eventBus)
        } else {
            await executeStop(client: client, eventBus: eventBus)
        }
        return WatchAdvertisementsResponse()
    }

    private func executeStart(client: BluetoothClient, eventBus: EventBus) async {
        await eventBus.attachEventListener(forKey: .advertisement) { (result: Result<AdvertisementEvent, any Error>) in
            guard case let .success(event) = result else { return }
            guard event.peripheral.id == request.peripheralId else { return }
            // TODO: Filter both serviceData and manufacturerData as per https://webbluetoothcg.github.io/web-bluetooth/#device-discovery
            // This means only allowing what is in the filters if provided, and in the case of acceptAllAdvertisements only
            // allow what is in optionalServices/optionalManufacturerData after applying the blocklist.
            // This further means we need to keep track of the options provided to the original requestDevice or requestLEScan
            await eventBus.sendJsEvent(event.toJs(targetId: request.peripheralId.uuidString.lowercased()))
        }
        client.startScanning(serviceUuids: [])
    }

    private func executeStop(client: BluetoothClient, eventBus: EventBus) async {
        client.stopScanning()
        await eventBus.detachListener(forKey: EventRegistrationKey.advertisement)
    }
}
