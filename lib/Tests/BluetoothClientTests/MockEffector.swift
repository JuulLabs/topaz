import Bluetooth
@testable import BluetoothClient
import Foundation

struct MockEffector: BluetoothEffector {

    var client: RequestClient
    var mockReady: @Sendable () throws -> Void
    var mockRun: @Sendable (Message.Action, UUID, @Sendable (RequestClient) -> Void) async throws -> Void

    init(
        client: RequestClient = .testValue,
        mockReady: @escaping @Sendable () throws -> Void = { fatalError("Not implemented") },
        mockRun: (@Sendable (Message.Action, UUID, @Sendable (RequestClient) -> Void) async throws -> Void)? = nil
    ) {
        self.client = client
        self.mockReady = mockReady
        self.mockRun = mockRun ?? { _, _, effect in effect(client) }
    }

    func bluetoothReadyState() async throws {
        try mockReady()
    }

    func runEffect(action: Message.Action, uuid: UUID, effect: @Sendable (RequestClient) -> Void) async throws {
        try await mockRun(action, uuid, effect)
    }
}
