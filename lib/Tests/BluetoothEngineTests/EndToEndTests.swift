import Bluetooth
@testable import BluetoothAction
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import DevicePicker
import Foundation
import JsMessage
import Testing
import XCTest

@Suite(.timeLimit(.minutes(1)))
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
        let engineSut = await withClient { _, client, selector in
            client.onEnable = { }
            client.onSystemState = { SystemStateEvent(.poweredOn) }
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

    @Test
    func handleDelegateEvent_withCharacteristicValueEvent_sendsJsEventBeforeResolving() async throws {
        let fake = FakePeripheral(name: "", identifier: UUID(n: 0))
        let characteristic = Characteristic(
            uuid: UUID(n: 1),
            instance: 0,
            properties: [],
            value: nil,
            descriptors: [],
            isNotifying: false
        )
        let state = BluetoothState(systemState: .poweredOn, peripherals: [fake.eraseToAnyPeripheral()])

        let eventExpectation = XCTestExpectation(description: "Receive event")
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!)) { event in
            #expect(event.eventName == "characteristicvaluechanged")
            eventExpectation.fulfill()
            return .success(())
        }

        var client = MockBluetoothClient()
        let resolveExpectation = XCTestExpectation(description: "Resolve pending request")
        client.onResolvePendingRequests = { event in
            #expect(event.name == .characteristicValue)
            resolveExpectation.fulfill()
        }

        let sut = BluetoothEngine(state: state, client: client, deviceSelector: await TestDeviceSelector())
        await sut.didAttach(to: context)
        client.eventsContinuation.yield(CharacteristicEvent(.characteristicValue, fake.eraseToAnyPeripheral(), characteristic))

        // It is critical that Js sees the `characteristicvaluechanged` event before the promise is resolved
        await XCTWaiter().fulfillment(of: [eventExpectation, resolveExpectation], timeout: 1.0, enforceOrder: true)
    }

}
