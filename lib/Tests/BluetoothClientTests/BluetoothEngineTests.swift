import Testing
import Bluetooth
@testable import BluetoothClient

struct BluetoothEngineTests {

    @Test(arguments: [
        SystemState.resetting,
        SystemState.poweredOn,
    ])
    func process_getAvailability_returnsTrue(state: SystemState) async throws {
        let node = WebNode(id: 0, sendEvent: { _ in })
        var client = BluetoothClient(request: .testValue, response: .testValue)
        client.request.enable = { state }

        let sut = BluetoothEngine(client: client)
        let response = await sut.process(request: .getAvailability, for: node)

        guard case let .availability(isAvailable) = response else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(isAvailable == true)
    }

    @Test(arguments: [
        SystemState.unknown,
        SystemState.unsupported,
        SystemState.unauthorized,
        SystemState.poweredOff,
    ])
    func process_getAvailability_returnsFalse(state: SystemState) async throws {
        let node = WebNode(id: 0, sendEvent: { _ in })
        var client = BluetoothClient(request: .testValue, response: .testValue)
        client.request.enable = { state }

        let sut = BluetoothEngine(client: client)
        let response = await sut.process(request: .getAvailability, for: node)

        guard case let .availability(isAvailable) = response else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(isAvailable == false)
    }
}
