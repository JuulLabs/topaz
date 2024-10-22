import Testing
import Bluetooth
@testable import BluetoothClient

struct BluetoothEngineTests {

    private func withClient(
        inject: (_ request: inout RequestClient, _ response: inout ResponseClient) -> Void
    ) -> BluetoothEngine {
        var request = RequestClient.testValue
        var response = ResponseClient.testValue
        inject(&request, &response)
        let client = BluetoothClient(request: request, response: response)
        return BluetoothEngine(client: client)
    }

    @Test(arguments: [
        SystemState.resetting,
        SystemState.poweredOn,
    ])
    func process_getAvailability_returnsTrue(state: SystemState) async throws {
        let sut = withClient { request, response in
            request.enable = { }
            response.events = AsyncStream { continuation in
                continuation.yield(.systemState(state))
            }
        }
        let response = await sut.process(request: .getAvailability)

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
        let sut = withClient { request, response in
            request.enable = { }
            response.events = AsyncStream { continuation in
                continuation.yield(.systemState(state))
            }
        }
        let response = await sut.process(request: .getAvailability)

        guard case let .availability(isAvailable) = response else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(isAvailable == false)
    }
}
