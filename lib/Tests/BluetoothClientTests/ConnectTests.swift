import Bluetooth
@testable import BluetoothClient
import Foundation
import JsMessage
import Testing

struct ConnectTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")

    @Test
    func connectRequest_decode() async throws {
        let body: [String: JsType] = [
            "uuid": .string(zeroUuid.uuidString),
        ]
        let request = ConnectRequest.decode(from: body)
        #expect(request?.peripheralId == zeroUuid)
    }

    @Test
    func connectResponse_encode() async throws {
        let response = ConnectResponse()
        let decoded: NSDictionary! = response.encodeForTesting()
        #expect(decoded == ["connected": true])
    }

    @Test
    func executeConnector_whenNotReady_throws() async throws {
        let effector = MockEffector(
            mockReady: { throw BluetoothError.unavailable }
        )
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        await #expect(throws: BluetoothError.self) {
            try await sut.execute(state: BluetoothState(), effector: effector)
        }
    }

    @Test
    func executeConnector_withAlreadyConnectedPeripheral_respondsWithIsConnectedTrue() async throws {
        let effector = MockEffector(mockReady: {})
        let peripheral = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .connected)
        let state = BluetoothState(peripherals: [peripheral.eraseToAnyPeripheral()])
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        let response = try await sut.execute(state: state, effector: effector)
        #expect(response.isConnected == true)
    }

    @Test
    func executeConnector_withConnectablePeripheral_respondsWithIsConnectedTrue() async throws {
        let disconnectedPeripheral = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .disconnected)
        let state = BluetoothState(peripherals: [disconnectedPeripheral.eraseToAnyPeripheral()])
        let effector = MockEffector(
            mockReady: {},
            mockRun: { _, _, _ in
                let connectedPeripheral = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .connected)
                await state.addPeripheral(connectedPeripheral.eraseToAnyPeripheral())
            }
        )
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        let response = try await sut.execute(state: state, effector: effector)
        #expect(response.isConnected == true)
    }

    @Test
    func executeConnector_withUnconnectablePeripheral_throws() async throws {
        let peripheral = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .disconnected)
        let state = BluetoothState(peripherals: [peripheral.eraseToAnyPeripheral()])
        let effector = MockEffector(
            mockReady: {},
            mockRun: { _, _, _ in
                throw BluetoothError.unknown
            }
        )
        let request = ConnectRequest(peripheralId: zeroUuid)
        let sut = Connector(request: request)
        await #expect(throws: BluetoothError.self) {
            try await sut.execute(state: state, effector: effector)
        }
    }
}
