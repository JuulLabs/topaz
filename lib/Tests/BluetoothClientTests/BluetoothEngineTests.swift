import Bluetooth
@testable import BluetoothClient
import DevicePicker
import Testing

struct BluetoothEngineTests {

    private func withClient(
        inject: (_ request: inout RequestClient, _ response: inout ResponseClient) -> Void
    ) async -> BluetoothEngine {
        var request = RequestClient.testValue
        var response = ResponseClient.testValue
        inject(&request, &response)
        let client = BluetoothClient(request: request, response: response)
        let selector = await TestDeviceSelector()
        return BluetoothEngine(deviceSelector: selector, client: client)
    }

    @Test(arguments: [
        SystemState.resetting,
        SystemState.poweredOn,
    ])
    func process_getAvailability_returnsTrue(state: SystemState) async throws {
        let sut = await withClient { request, response in
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
        // SystemState.unknown, - excluded because we block until != unknown
        SystemState.unsupported,
        SystemState.unauthorized,
        SystemState.poweredOff,
    ])
    func process_getAvailability_returnsFalse(state: SystemState) async throws {
        let sut = await withClient { request, response in
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
