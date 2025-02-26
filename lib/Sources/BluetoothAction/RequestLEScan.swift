import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage

struct RequestLEScanOptions: JsMessageDecodable {
    let rawFilters: [JsType]
    let acceptAllAdvertisements: Bool
    let keepRepeatedDevices: Bool

    static func decode(from data: [String: JsType]?) -> Self? {
        let options = data?["options"]?.dictionary
        let rawFilters = options?["filters"]?.array ?? []
        let acceptAllAdvertisements = options?["acceptAllAdvertisements"]?.number?.boolValue ?? false
        let keepRepeatedDevices = options?["keepRepeatedDevices"]?.number?.boolValue ?? false
        return .init(rawFilters: rawFilters, acceptAllAdvertisements: acceptAllAdvertisements, keepRepeatedDevices: keepRepeatedDevices)
    }

    func decodeAndValidateFilters() throws -> [Options.Filter] {
        let filters = try rawFilters.compactMap { try Options.Filter.decode(from: $0.dictionary) }
        if acceptAllAdvertisements && !filters.isEmpty {
            // TODO: should actually throw a TypeError not a DOMError
            throw OptionsError.invalidInput("Cannot set acceptAllAdvertisements to true if filters are provided")
        }
        if !acceptAllAdvertisements && filters.isEmpty {
            // TODO: should actually throw a TypeError not a DOMError
            throw OptionsError.invalidInput("Cannot set acceptAllAdvertisements to false without providing filters")
        }
        return filters
    }
}

enum RequestLEScanRequest: JsMessageDecodable {
    case start(options: RequestLEScanOptions)
    case stop(id: String)

    static func decode(from data: [String: JsType]?) -> Self? {
        if data?["stop"]?.number?.boolValue == true {
            guard let scanId = data?["scanId"]?.string else { return nil }
            return .stop(id: scanId)
        }
        return RequestLEScanOptions.decode(from: data).map { .start(options: $0) }
    }
}

enum RequestLEScanResponse: JsMessageEncodable {
    case start(id: String, scan: BluetoothLEScan)
    case stop

    func toJsMessage() -> JsMessage.JsMessageResponse {
        switch self {
        case let .start(id, scan):
            .body([
                "scanId": id,
                "active": scan.active,
                "acceptAllAdvertisements": scan.acceptAllAdvertisements,
                "keepRepeatedDevices": scan.keepRepeatedDevices,
                "filters": [], // TODO: map to Js values
            ])
        case .stop:
            .body([
                "active": false,
            ])
        }
    }
}

struct RequestLEScan: BluetoothAction {
    let requiresReadyState: Bool = true
    let request: RequestLEScanRequest
    let jsEventForwarder: JsEventForwarder

    init(request: RequestLEScanRequest) {
        self.request = request
        self.jsEventForwarder = JsEventForwarder { _ in }
    }

    init(request: RequestLEScanRequest, jsEventForwarder: JsEventForwarder) {
        self.request = request
        self.jsEventForwarder = jsEventForwarder
    }

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> RequestLEScanResponse {
        switch request {
        case let .start(options):
            try await executeStart(state: state, client: client, options: options)
        case let .stop(scanId):
            try await executeStop(state: state, client: client, scanId: scanId)
        }
    }

    private func executeStart(state: BluetoothState, client: BluetoothClient, options: RequestLEScanOptions) async throws -> RequestLEScanResponse {
        print("executeStart")
        let scanId = UUID().uuidString
        let filters = try options.decodeAndValidateFilters()
        let activeScan = BluetoothLEScan(
            filters: filters,
            keepRepeatedDevices: options.keepRepeatedDevices,
            acceptAllAdvertisements: options.acceptAllAdvertisements,
            active: true
        )
        let task = Task { [jsEventForwarder] in
            print("Start scanning now")
            let scanner = await client.scan(options: activeScan.toFilterOptions())
            defer {
                print("Scanner cancelled")
                scanner.cancel()
            }
            print("Await advertisements")
            for await event in scanner.advertisements {
                guard !Task.isCancelled else { return }
                print("TODO: got advertisement \(event.advertisement.localName ?? "unnamed")")
                await jsEventForwarder.forwardEvent(event.jsAdvertismentEvent())
                // TODO: keep track of these devices because Js will try to connect one of them next
            }
        }
        let scanTask = ScanTask(id: scanId, scan: activeScan, task: task)
        await state.addScanTask(scanTask)
        // TODO: add scan to navigator.bluetooth.[[activeScans]]
        return .start(id: scanId, scan: activeScan)
    }

    private func executeStop(state: BluetoothState, client: BluetoothClient, scanId: String) async throws -> RequestLEScanResponse {
        print("executeStop")
        if let scanTask = await state.removeScanTask(id: scanId) {
            scanTask.cancel()
        }
        return .stop
    }
}

extension AdvertisementEvent {
    public func jsAdvertismentEvent() -> JsEvent {
        // https://webbluetoothcg.github.io/web-bluetooth/#advertising-events
        let jsAdvertisement: [String: JsConvertable] = [
            "uuids": peripheral.services.map { $0.uuid },
            "name": advertisement.localName ?? jsNull,
            "rssi": advertisement.rssi,
            "txPower": advertisement.txPowerLevel ?? jsNull,
            "manufacturerData": advertisement.manufacturerData?.asJsDictionary(),
            "serviceData": advertisement.serviceData.asJsDictionary(),
        ]
        let jsDevice: [String: JsConvertable] = [
            "uuid": peripheral.id,
            "name": peripheral.name ?? jsNull,
        ]
        let body: [String: JsConvertable] = [
            "advertisement": jsAdvertisement,
            "device": jsDevice,
        ]
        return JsEvent(targetId: "bluetooth", eventName: "advertisementreceived", body: body)
    }
}

extension ManufacturerData {
    func asJsDictionary() -> [String: JsConvertable] {
        ["code": code, "data": data]
    }
}

extension ServiceData {
    func asJsDictionary() -> [String: JsConvertable] {
        rawData.reduce(into: [:]) { dict, item in
            dict[item.key.uuidString.lowercased()] = item.value
        }
    }
}
