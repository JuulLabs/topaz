import Bluetooth
import BluetoothClient
import Foundation

/**
 Provides a mechanism to play effects against the bluetooth system with a direct call
 interface. Effects are suspended in a continuation until the corresponding delegate
 event is received and mediated back to the caller via the promise store.
 */
actor EffectRunner {
    private var systemState: SystemState = .unknown
    private let client: RequestClient

    private var promiseStore = PromiseStore<Effect>()
    private var isEnabled: Bool = false

    init(
        client: RequestClient
    ) {
        self.client = client
    }

    // MARK: - DelegateEventProcessor

    nonisolated func ingestDelegateEvent(_ event: DelegateEvent) async {
        await updateLocalState(for: event)
        await resolvePromises(for: event)
    }

    nonisolated func cancelAllEvents(with error: any Error) async {
        await rejectAllPromises(with: error)
    }

    // MARK: - Effector

    func systemState(predicate: (@Sendable (SystemState) throws -> Bool)? = nil) async throws -> SystemStateEffect {
        var result = SystemStateEffect(self.systemState)
        guard let predicate else { return result }
        while try predicate(result.systemState) == false {
            result = try await awaitDelegateResponse(.systemState) { [needsEnable = !isEnabled] in
                // System state starts arriving via the delegate callback once we invoke enable
                if needsEnable {
                    client.enable()
                }
            }
            try Task.checkCancellation()
            self.isEnabled = true
        }
        return result
    }

    nonisolated func advertisement() async throws -> AdvertisementEffect {
        try await awaitDelegateResponse(.advertisement) {
            // nothing to do here - scanning is enabled/disabled externally
        }
    }

    nonisolated func connect(peripheral: AnyPeripheral) async throws -> PeripheralEffect {
        try await awaitDelegateResponse(.peripheral(.connect, peripheral)) {
            client.connect(peripheral)
        }
    }

    nonisolated func disconnect(peripheral: AnyPeripheral) async throws -> PeripheralEffect {
        try await awaitDelegateResponse(.peripheral(.disconnect, peripheral)) {
            client.disconnect(peripheral)
        }
    }

    nonisolated func discoverServices(peripheral: AnyPeripheral, filter: ServiceDiscoveryFilter) async throws -> PeripheralEffect {
        try await awaitDelegateResponse(.peripheral(.discoverServices, peripheral)) {
            client.discoverServices(peripheral, filter)
        }
    }

    nonisolated func discoverCharacteristics(peripheral: AnyPeripheral, filter: CharacteristicDiscoveryFilter) async throws -> PeripheralEffect {
        try await awaitDelegateResponse(.peripheral(.discoverCharacteristics, peripheral)) {
            client.discoverCharacteristics(peripheral, filter)
        }
    }

    nonisolated func characteristicRead(peripheral: AnyPeripheral, characteristic: Characteristic) async throws -> CharacteristicEffect {
        try await awaitDelegateResponse(.characteristic(.characteristicValue, peripheral, characteristic)) {
            // TODO: client.readCharacteristic()
        }
    }

    nonisolated func characteristicNotify(peripheral: AnyPeripheral, characteristic: Characteristic, enabled: Bool) async throws -> CharacteristicEffect {
        try await awaitDelegateResponse(.characteristic(.characteristicNotify, peripheral, characteristic)) {
            // TODO: client.setCharacteristicNotify(enabled)
        }
    }

    // MARK: - Private Logic

    private func awaitDelegateResponse<T: Effect>(
        _ key: EffectKey,
        launchEffect: @Sendable () -> Void
    ) async throws -> T {
        let result = try await withCheckedThrowingContinuation { continuation in
            promiseStore.register(continuation, with: key)
            launchEffect()
        }
        try Task.checkCancellation()
        guard let result = result as? T else {
            throw BluetoothError.unknown // TODO: system error
        }
        return result
    }

    private func updateLocalState(for event: DelegateEvent) async {
        switch event {
        case let .systemState(newState):
            self.systemState = newState
        default:
            break
        }
    }

    private func resolvePromises(for event: DelegateEvent) {
        let effect = event.toEffect()
        if let effect = effect as? ErrorEffect {
            promiseStore.reject(with: effect.error, for: effect.key)
        } else {
            promiseStore.resolve(with: effect, for: effect.key)
        }
    }

    private func rejectAllPromises(with error: any Error) {
        promiseStore.rejectAll(with: error)
    }
}

extension PromiseStore {
    @inlinable
    mutating func register(_ continuation: CheckedContinuation<Result, any Error>, effect key: EffectKey) {
        register(continuation, with: key)
    }
}
