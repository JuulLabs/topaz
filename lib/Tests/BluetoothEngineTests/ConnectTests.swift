import Bluetooth
import BluetoothClient
@testable import BluetoothEngine
import Effector
import Foundation
import JsMessage
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
    private let peripheral = { (uuid: UUID, connectionState: ConnectionState) in
        FakePeripheral(name: "bob", identifier: uuid, connectionState: connectionState)
            .eraseToAnyPeripheral()
    }
    private let readyEffector: Effector = {
        var effector = Effector.testValue
        effector.systemState = { _ in SystemStateEffect(.poweredOn) }
        return effector
    }()
    private let unReadyEffector: Effector = {
        var effector = Effector.testValue
        effector.systemState = { _ in SystemStateEffect(.poweredOff) }
        return effector
    }()
    private let effectorThatThrows: Effector = {
        var effector = Effector.testValue
        effector.systemState = { _ in SystemStateEffect(.poweredOn) }
        effector.connect = { _ in
            // All the effect machinery either succeeds or throws - simulate the failure case by throwing
            throw BluetoothError.unknown
        }
        return effector
    }()
    private let effectorThatConnects = { (state: BluetoothState) throws in
        var effector = Effector.testValue
        effector.systemState = { _ in SystemStateEffect(.poweredOn) }
        effector.connect = { peripheral in
            let connectedPeripheral = FakePeripheral(
                name: peripheral.name!,
                identifier: peripheral.identifier,
                connectionState: .connected
            ).eraseToAnyPeripheral()
            state.putPeripheral(connectedPeripheral)
            return PeripheralEffect(.connect, connectedPeripheral)
        }
        return effector
    }

    @Test
    func execute_whenNotReady_throwsAnyError() async {
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        await #expect(throws: (any Error).self) {
            try await sut.execute(state: BluetoothState(), effector: unReadyEffector)
        }
    }

    @Test
    func execute_withAlreadyConnectedPeripheral_respondsWithIsConnectedTrue() async throws {
        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .connected)])
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        let response = try await sut.execute(state: state, effector: readyEffector)
        #expect(response.isConnected == true)
    }

    @Test
    func execute_withConnectablePeripheral_respondsWithIsConnectedTrue() async throws {
        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .disconnected)])
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        let response = try await sut.execute(state: state, effector: effectorThatConnects(state))
        #expect(response.isConnected == true)
    }

    @Test
    func execute_withFailingEffect_throwsAnyError() async {
        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .disconnected)])
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        await #expect(throws: (any Error).self) {
            try await sut.execute(state: state, effector: effectorThatThrows)
        }
    }
}
