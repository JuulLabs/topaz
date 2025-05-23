import Bluetooth
@testable import BluetoothAction
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import DevicePicker
import EventBus
import Foundation
import Helpers
import JsMessage
import Testing
import XCTest

@Suite(.timeLimit(.minutes(1)))
struct EndToEndBluetoothEngineTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    private let fakeServiceId = UUID(n: 9)
    private let eventBus = EventBus()

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
        let selectorSut = await DeviceSelector()
        let engineSut = await withClient(eventBus: eventBus) { _, client, selector in
            client.onEnable = { eventBus.enqueueEvent(SystemStateEvent(.poweredOn)) }
            client.onStartScanning = { _ in
                eventBus.enqueueEvent(AdvertisementEvent(fake, fake.fakeAdvertisement(rssi: 0)))
            }
            client.onStopScanning = { }
            selector = selectorSut
        }

        await engineSut.didAttach(to: context)
        async let promise = await engineSut.process(request: requestDeviceRequest, in: context)
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
        let store = InMemoryStorage()
        try await store.save([UUID(n: 0)], for: .uuidsKey)
        let state = BluetoothState(systemState: .poweredOn, store: store)

        let eventExpectation = XCTestExpectation(description: "Receive event")
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!)) { event in
            #expect(event.eventName == "characteristicvaluechanged")
            eventExpectation.fulfill()
            return .success(())
        }

        let resolveExpectation = XCTestExpectation(description: "Resolve pending request")
        let resolveTask = Task {
            let _: CharacteristicChangedEvent = try await eventBus.awaitEvent(
                forKey: .characteristic(
                    .characteristicValue,
                    peripheralId: fake.id,
                    serviceId: fakeServiceId,
                    characteristicId: characteristic.uuid,
                    instance: characteristic.instance)
            )
            resolveExpectation.fulfill()
        }

        let sut = BluetoothEngine(eventBus: eventBus, state: state, client: MockBluetoothClient(), deviceSelector: await TestDeviceSelector())
        await sut.didAttach(to: context)
        eventBus.enqueueEvent(
            CharacteristicChangedEvent(peripheralId: fake.id, serviceId: fakeServiceId, characteristicId: characteristic.uuid, instance: characteristic.instance, data: nil)
        )

        // It is critical that Js sees the `characteristicvaluechanged` event before the promise is resolved
        let outcome = await XCTWaiter().fulfillment(of: [eventExpectation, resolveExpectation], timeout: 1.0, enforceOrder: true)
        #expect(outcome == .completed)
        resolveTask.cancel()
    }

    @Test
    func handleDelegateEvent_withUnexpectedDisconnectionEvent_sendsJsEventBeforeResolvingAndRejecting() async throws {
        let fake = FakePeripheral(id: UUID(n: 0))
        let store = InMemoryStorage()
        try await store.save([UUID(n: 0)], for: .uuidsKey)
        let state = BluetoothState(systemState: .poweredOn, store: store)

        let eventExpectation = XCTestExpectation(description: "Receive event")
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!)) { event in
            #expect(event.eventName == "gattserverdisconnected")
            eventExpectation.fulfill()
            return .success(())
        }

        // Check that regular targeted disconnect event propagates first
        let resolveExpectation = XCTestExpectation(description: "Resolve due to disconnection")
        let resolveTask = Task {
            let _: DisconnectionEvent = try await eventBus.awaitEvent(forKey: .peripheral(.disconnect, fake))
            resolveExpectation.fulfill()
        }

        // Check that other requests are subsequently rejected with a wildcard error event
        let rejectExpectation = XCTestExpectation(description: "Reject due to disconnection error")
        let rejectTask = Task {
            do {
                let _: PeripheralEvent = try await eventBus.awaitEvent(forKey: .peripheral(.discoverServices, fake))
            } catch {
                rejectExpectation.fulfill()
            }
        }

        let sut = BluetoothEngine(eventBus: eventBus, state: state, client: MockBluetoothClient(), deviceSelector: await TestDeviceSelector())
        await sut.didAttach(to: context)
        eventBus.enqueueEvent(DisconnectionEvent.unexpected(fake, BluetoothError.unknown))

        let outcome = await XCTWaiter().fulfillment(of: [eventExpectation, resolveExpectation, rejectExpectation], timeout: 1.0, enforceOrder: true)
        #expect(outcome == .completed)
        resolveTask.cancel()
        rejectTask.cancel()
    }
}

fileprivate extension String {
    static let uuidsKey = "savedPeripheralUUIDs"
}
