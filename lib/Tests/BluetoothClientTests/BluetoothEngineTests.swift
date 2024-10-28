import Bluetooth
@testable import BluetoothClient
import Testing

struct BluetoothEngineTests {

    @Test(arguments: [
        SystemState.resetting,
        SystemState.poweredOn,
    ])
    func process_getAvailability_returnsTrue(state: SystemState) async throws {
        let sut = await withClient { request, response, _ in
            request.enable = { }
            response.events = AsyncStream { continuation in
                continuation.yield(.systemState(state))
            }
        }
        let response = try await sut.process(message: Message(action: .getAvailability))
        guard let response = response as? GetAvailabilityResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isAvailable == true)
    }

    @Test(arguments: [
        // SystemState.unknown, - excluded because we block until != unknown
        SystemState.unsupported,
        SystemState.unauthorized,
        SystemState.poweredOff,
    ])
    func process_getAvailability_returnsFalse(state: SystemState) async throws {
        let sut = await withClient { request, response, _ in
            request.enable = { }
            response.events = AsyncStream { continuation in
                continuation.yield(.systemState(state))
            }
        }
        let response = try await sut.process(message: Message(action: .getAvailability))
        guard let response = response as? GetAvailabilityResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isAvailable == false)
    }
}
