import Bluetooth
import BluetoothClient

extension BluetoothClient {
    public func awaitSystemState(predicate: @Sendable (SystemState) throws -> Bool) async throws -> SystemState {
        var result: SystemState = .unknown
        repeat {
            try Task.checkCancellation()
            result = try await self.systemState().systemState
        } while try predicate(result) == false
        return result
    }
}
