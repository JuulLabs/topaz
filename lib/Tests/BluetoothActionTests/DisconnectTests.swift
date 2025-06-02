import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import TestHelpers
import Testing

extension Tag {
    @Tag static var disconnect: Self
}

@Suite(.tags(.disconnect))
struct DisonnectRequestTests {
    @Test
    func decode_withValidUuid_succeeds() {
        let uuid = UUID(n: 0)
        let body: [String: JsType] = [
            "uuid": .string(uuid.uuidString),
        ]
        let request = DisconnectRequest.decode(from: body)
        #expect(request?.peripheralId == uuid)
    }

    @Test
    func decode_withExtraBodyData_succeedsAndIgnoresExtras() {
        let uuid = UUID(n: 0)
        let body: [String: JsType] = [
            "uuid": .string(uuid.uuidString),
            "bananaCount": .number(42),
        ]
        let request = DisconnectRequest.decode(from: body)
        #expect(request?.peripheralId == uuid)
    }

    @Test
    func decode_withInvalidUuid_isNil() {
        let body: [String: JsType] = [
            "uuid": .string("bananaman"),
        ]
        let request = DisconnectRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withEmptyBody_isNil() {
        let body: [String: JsType] = [:]
        let request = DisconnectRequest.decode(from: body)
        #expect(request == nil)
    }
}

@Suite(.tags(.disconnect))
struct DisonnectResponseTests {
    @Test
    func toJsMessage_withDefaultResponse_hasExpectedBody() throws {
        let sut = DisconnectResponse()
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        #expect(body == ["disconnected": true])
    }
}

@Suite(.tags(.disconnect))
struct DisconnectorTests {
    private let zeroUuid: UUID = UUID(n: 0)

    @Test
    func execute_withAlreadyDisconnectedPeripheral_respondsWithIsDisconnectedTrue() async throws {
        let state = BluetoothState(peripherals: [FakePeripheral(id: zeroUuid, connectionState: .disconnected)])
        let request = DisconnectRequest(peripheralId: zeroUuid)
        let sut = Disconnector(request: request)
        let response = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        #expect(response.isDisconnected == true)
    }

    @Test
    func execute_withRequestedDisconnection_respondsWithIsDisconnectedTrue() async throws {
        let state = BluetoothState(peripherals: [FakePeripheral(id: zeroUuid, connectionState: .connected)])
        let request = DisconnectRequest(peripheralId: zeroUuid)
        let eventBus = await selfResolvingEventBus()
        var client = MockBluetoothClient()
        client.onDisconnect = { _ in
            let disconnectedDevice = FakePeripheral(id: zeroUuid, connectionState: .disconnected)
            eventBus.enqueueEvent(DisconnectionEvent.requested(disconnectedDevice))
        }
        let sut = Disconnector(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.isDisconnected == true)
    }

    @Test
    func execute_withUnexpectedDisconnection_respondsWithIsDisconnectedTrue() async throws {
        let state = BluetoothState(peripherals: [FakePeripheral(id: zeroUuid, connectionState: .connected)])
        let request = DisconnectRequest(peripheralId: zeroUuid)
        let eventBus = await selfResolvingEventBus()
        var client = MockBluetoothClient()
        client.onDisconnect = { _ in
            let disconnectedDevice = FakePeripheral(id: zeroUuid, connectionState: .disconnected)
            eventBus.enqueueEvent(DisconnectionEvent.unexpected(disconnectedDevice, TestError()))
        }
        let sut = Disconnector(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.isDisconnected == true)
    }
}

@Suite(.tags(.disconnect))
struct DisconnectionEventTests {
    @Test
    func gattServerDisconnectedEvent_requestedDisconnectAsJsValue_hasExpectedBody() throws {
        let deviceUuid = UUID(n: 0)
        let disconnectedDevice = FakePeripheral(id: deviceUuid, connectionState: .disconnected)
        let sut = DisconnectionEvent.requested(disconnectedDevice)
        let jsEvent = sut.gattServerDisconnectedEvent()

        // Convert the event to the Js representation
        let encoded = jsEvent.jsValue
        // Convert it back to the native representation so we can check the values
        let decoded = try #require(JsType.bridge(encoded).dictionary)
        let decodedBody = try #require(decoded["data"]?.dictionary)

        // Event properties
        #expect(decoded["id"]?.string == deviceUuid.uuidString.lowercased())
        #expect(decoded["name"]?.string == "gattserverdisconnected")

        // Event data properties
        #expect(decodedBody["reason"]?.string == "disconnected")
    }

    @Test
    func gattServerDisconnectedEvent_unexpectedDisconnectAsJsValue_hasExpectedBody() throws {
        let deviceUuid = UUID(n: 0)
        let disconnectedDevice = FakePeripheral(id: deviceUuid, connectionState: .disconnected)
        let sut = DisconnectionEvent.unexpected(disconnectedDevice, TestError())
        let jsEvent = sut.gattServerDisconnectedEvent()

        // Convert the event to the Js representation
        let encoded = jsEvent.jsValue
        // Convert it back to the native representation so we can check the values
        let decoded = try #require(JsType.bridge(encoded).dictionary)
        let decodedBody = try #require(decoded["data"]?.dictionary)

        // Event properties
        #expect(decoded["id"]?.string == deviceUuid.uuidString.lowercased())
        #expect(decoded["name"]?.string == "gattserverdisconnected")

        // Event data properties
        #expect(decodedBody["reason"]?.string == "Test error reason")
    }
}

private struct TestError: Error { }

extension TestError: LocalizedError {
    var errorDescription: String? {
        "Test error reason"
    }
}
