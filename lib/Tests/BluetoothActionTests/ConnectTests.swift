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
    @Tag static var connect: Self
}

@Suite(.tags(.connect))
struct ConnectRequestTests {
    @Test
    func decode_withValidUuid_succeeds() {
        let uuid = UUID(n: 0)
        let body: [String: JsType] = [
            "uuid": .string(uuid.uuidString),
        ]
        let request = ConnectRequest.decode(from: body)
        #expect(request?.peripheralId == uuid)
    }

    @Test
    func decode_withExtraBodyData_succeedsAndIgnoresExtras() {
        let uuid = UUID(n: 0)
        let body: [String: JsType] = [
            "uuid": .string(uuid.uuidString),
            "bananaCount": .number(42),
        ]
        let request = ConnectRequest.decode(from: body)
        #expect(request?.peripheralId == uuid)
    }

    @Test
    func decode_withInvalidUuid_isNil() {
        let body: [String: JsType] = [
            "uuid": .string("bananaman"),
        ]
        let request = ConnectRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withEmptyBody_isNil() {
        let body: [String: JsType] = [:]
        let request = ConnectRequest.decode(from: body)
        #expect(request == nil)
    }
}

@Suite(.tags(.connect))
struct ConnectResponseTests {
    @Test
    func toJsMessage_withDefaultResponse_hasExpectedBody() throws {
        let sut = ConnectResponse()
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        #expect(body == ["connected": true])
    }
}

@Suite(.tags(.connect))
struct ConnectorTests {
    private let zeroUuid: UUID = UUID(n: 0)

    @Test
    func execute_withAlreadyConnectedPeripheral_respondsWithIsConnectedTrue() async throws {
        let state = BluetoothState(peripherals: [FakePeripheral(id: zeroUuid, connectionState: .connected)])
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        let response = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        #expect(response.isConnected == true)
    }

    @Test
    func execute_withConnectablePeripheral_respondsWithIsConnectedTrue() async throws {
        let state = BluetoothState(peripherals: [FakePeripheral(id: zeroUuid, connectionState: .disconnected)])
        let request = ConnectRequest(peripheralId: zeroUuid)
        let eventBus = await selfResolvingEventBus()
        var client = MockBluetoothClient()
        client.onConnect = { _ in
            eventBus.enqueueEvent(PeripheralEvent(.connect, FakePeripheral(id: zeroUuid, connectionState: .connected)))
        }
        let sut = Connector(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.isConnected == true)
    }
}
