import Bluetooth
import BluetoothClient

extension Effector {
    public static func liveValue(client: RequestClient) -> Self {
        let runner = EffectRunner(client: client)
        return Effector(
            onDelegateEvent: { await runner.ingestDelegateEvent($0) },
            onCancelEvents: { await runner.cancelAllEvents(with: $0) },
            systemState: { try await runner.systemState(predicate: $0) },
            advertisement: { try await runner.advertisement() },
            connect: { try await runner.connect(peripheral: $0) },
            disconnect: { try await runner.disconnect(peripheral: $0) },
            discoverServices: { try await runner.discoverServices(peripheral: $0, filter: $1) },
            discoverCharacteristics: { try await runner.discoverCharacteristics(peripheral: $0, filter: $1) },
            characteristicNotify: { try await runner.characteristicNotify(peripheral: $0, characteristic: $1, enabled: $2) },
            characteristicRead: { try await runner.characteristicRead(peripheral: $0, characteristic: $1) }
        )
    }
}

extension Effector {
    /// Blocks until we are in powered on state
    /// Throws an error if the state is not powered on
    public func bluetoothReadyState() async throws {
        _ = try await systemState { state in
            switch state {
            case .poweredOn:
                true
            case .unsupported, .unauthorized, .poweredOff:
                throw BluetoothError.unavailable
            case .unknown, .resetting:
                // Keep waiting - the system emits unknown until it has finished starting up
                false
            }
        }
    }
}
