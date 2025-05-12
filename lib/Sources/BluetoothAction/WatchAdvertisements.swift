import Bluetooth
import BluetoothClient
import BluetoothMessage
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
    let jsEventForwarder: JsEventForwarder

    init(request: WatchAdvertisementsRequest) {
        self.request = request
        self.jsEventForwarder = JsEventForwarder { _ in }
    }

    init(request: WatchAdvertisementsRequest, jsEventForwarder: JsEventForwarder) {
        self.request = request
        self.jsEventForwarder = jsEventForwarder
    }

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> WatchAdvertisementsResponse {
        if request.enable {
            await executeStart(state: state, client: client)
        } else {
            await executeStop(state: state)
        }
        return WatchAdvertisementsResponse()
    }

    private func executeStart(state: BluetoothState, client: BluetoothClient) async {
        let task = Task { [jsEventForwarder, targetId = request.peripheralId] in
            let scanner = await client.scan(options: nil)
            defer {
                scanner.cancel()
            }
            for await event in scanner.advertisements {
                guard !Task.isCancelled else { return }
                if event.peripheral.id == targetId {
                    // TODO: Filter both serviceData and manufacturerData as per https://webbluetoothcg.github.io/web-bluetooth/#device-discovery
                    // This means only allowing what is in the filters if provided, and in the case of acceptAllAdvertisements only
                    // allow what is in optionalServices/optionalManufacturerData after applying the blocklist.
                    // This further means we need to keep track of the options provided to the original requestDevice or requestLEScan
                    await jsEventForwarder.forwardEvent(event.toJs(targetId: targetId.uuidString.lowercased()))
                }
            }
        }
        let scanTask = ScanTask(id: request.peripheralId.uuidString, task: task)
        await state.addScanTask(scanTask)
    }

    private func executeStop(state: BluetoothState) async {
        if let scanTask = await state.removeScanTask(id: request.peripheralId.uuidString) {
            scanTask.cancel()
        }
    }
}
