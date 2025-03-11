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
            "data": .dictionary(["options": JsType.bridge(["acceptAllDevices": true])]),
        ]
    )

    /// Tests the integration of:
    /// 1. web app initiating a promise to request a device
    /// 2. bluetooth emitting advertisements for a device
    /// 3. user selecting the device from the picker
    /// 4. engine fulfills the selected device promise
    @Test func process_requestDevice_returnsDeviceWhenSelected() async throws {
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!), eventSink: { _ in .success(()) })
        let fake = FakePeripheral(id: zeroUuid, name: "bob")
        let scanner = MockScanner()
        let selectorSut = await DeviceSelector()
        let engineSut = await withClient { _, client, selector in
            client.onEnable = { }
            client.onSystemState = { SystemStateEvent(.poweredOn) }
            client.onScan = { _ in scanner }
            selector = selectorSut
        }

        await engineSut.didAttach(to: context)
        async let promise = await engineSut.process(request: requestDeviceRequest, in: context)
        scanner.continuation.yield(AdvertisementEvent(fake, fake.fakeAdvertisement(rssi: 0)))
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
        let fake = FakePeripheral(id: UUID(n: 0))
        let characteristic = FakeCharacteristic(uuid: UUID(n: 1))
        let state = BluetoothState(systemState: .poweredOn, peripherals: [fake])

        let eventExpectation = XCTestExpectation(description: "Receive event")
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!)) { event in
            #expect(event.eventName == "characteristicvaluechanged")
            eventExpectation.fulfill()
            return .success(())
        }

        var client = MockBluetoothClient()
        let resolveExpectation = XCTestExpectation(description: "Resolve pending request")
        client.onResolvePendingRequests = { event in
            #expect(event is CharacteristicChangedEvent)
            resolveExpectation.fulfill()
        }

        let sut = BluetoothEngine(state: state, client: client, deviceSelector: await TestDeviceSelector())
        await sut.didAttach(to: context)
        client.eventsContinuation.yield(
            CharacteristicChangedEvent(peripheralId: fake.id, characteristicId: characteristic.uuid, instance: characteristic.instance, data: nil)
        )

        // It is critical that Js sees the `characteristicvaluechanged` event before the promise is resolved
        let outcome = await XCTWaiter().fulfillment(of: [eventExpectation, resolveExpectation], timeout: 1.0, enforceOrder: true)
        #expect(outcome == .completed)
    }

    @Test
    func handleDelegateEvent_withUnexpectedDisconnectionEvent_sendsJsEventBeforeResolvingAndRejecting() async throws {
        let fake = FakePeripheral(id: UUID(n: 0))
        let state = BluetoothState(systemState: .poweredOn, peripherals: [fake])

        let eventExpectation = XCTestExpectation(description: "Receive event")
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!)) { event in
            #expect(event.eventName == "gattserverdisconnected")
            eventExpectation.fulfill()
            return .success(())
        }

        var client = MockBluetoothClient()
        let resolveExpectation = XCTestExpectation(description: "Resolve due to disconnection")
        let rejectExpectation = XCTestExpectation(description: "Reject due to disconnection error")
        client.onResolvePendingRequests = { event in
            #expect(event is ErrorEvent || event is DisconnectionEvent)
            // Check that regular targeted disconnect event propagates first
            if event is DisconnectionEvent {
                resolveExpectation.fulfill()
            }
            // Check that all remaining requests are subsequently rejected with a wildcard error event
            if event is ErrorEvent {
                rejectExpectation.fulfill()
            }
        }

        let sut = BluetoothEngine(state: state, client: client, deviceSelector: await TestDeviceSelector())
        await sut.didAttach(to: context)
        client.eventsContinuation.yield(
            DisconnectionEvent.unexpected(fake, BluetoothError.unknown)
        )

        let outcome = await XCTWaiter().fulfillment(of: [eventExpectation, resolveExpectation, rejectExpectation], timeout: 1.0, enforceOrder: true)
        #expect(outcome == .completed)
    }
}
