import Bluetooth
import BluetoothClient
@testable import BluetoothEngine
import DevicePicker
import Foundation
import JsMessage
import Testing

@Suite(.timeLimit(.minutes(1)), .disabled("Temporarily disabled for refactor"))
struct EndToEndBluetoothEngineTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")

    private let requestDeviceRequest = JsMessageRequest(
        handlerName: "bluetooth",
        body: [
            "action": .string("requestDevice"),
            "options": .dictionary([:]),
        ]
    )

    /// Tests the integration of:
    /// 1. web app initiating a promise to request a device
    /// 2. bluetooth emitting advertisements for a device
    /// 3. user selecting the device from the picker
    /// 4. engine fulfills the selected device promise
    @Test func process_requestDevice_returnsDeviceWhenSelected() async throws {
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid)
        let scanner = MockScanner()
        let selectorSut = await DeviceSelector()
        let engineSut: BluetoothEngine = await withClient { state, client, selector in
            client.onEnable = { [events = client.eventsContinuation] in
                events.yield(SystemStateEvent(.poweredOn))
            }
            client.onScan = { _ in scanner }
            selector = selectorSut
        }

        async let promise = await engineSut.process(request: requestDeviceRequest)
        scanner.continuation.yield(AdvertisementEvent(fake.eraseToAnyPeripheral(), fake.fakeAd(rssi: 0)))
        let advertisements = await selectorSut.advertisements.first(where: { !$0.isEmpty })
        #expect(advertisements!.count == 1)

        await selectorSut.makeSelection(advertisements!.first!.peripheralId)
        let response = await promise
        guard case let .body(responseBody) = response else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        guard let body = responseBody.jsValue as? [String: Any] else {
            Issue.record("Expected dictionary but got: \(response)")
            return
        }
        #expect(body["uuid"] as? String == zeroUuid.uuidString)
        #expect(body["name"] as? String == "bob")
    }

}
