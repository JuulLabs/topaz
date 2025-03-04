import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

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
        let task = Task { [jsEventForwarder] in
            // TODO: options for this device only, but combined with others?
            let scanner = await client.scan(options: nil)
            defer {
                // TODO: only cancel if no other watchers
                scanner.cancel()
            }
            for await event in scanner.advertisements {
                guard !Task.isCancelled else { return }
                await jsEventForwarder.forwardEvent(event.toJs())
            }
        }
        // TODO: need a different kind of scan for this one
        let activeScan = BluetoothLEScan(
            filters: [.init(name: "")],
            keepRepeatedDevices: false,
            acceptAllAdvertisements: false,
            active: true
        )
        let scanTask = ScanTask(id: request.peripheralId.uuidString, scan: activeScan, task: task)
        await state.addScanTask(scanTask)
    }

    private func executeStop(state: BluetoothState) async {
        if let scanTask = await state.removeScanTask(id: request.peripheralId.uuidString) {
            scanTask.cancel()
        }
    }
}
