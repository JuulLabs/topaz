import Bluetooth
import BluetoothClient
import Foundation
import Helpers

/**
 Provides a mechanism to play effects against the bluetooth system with a direct call
 interface. Effects are suspended in a continuation until the corresponding delegate
 event is received and mediated back to the caller via the promise store.

 TODO: lock this actor to the system Bluetooth DispatchQueue serial queue
 */
extension Effector {
    public static func liveValue(state: BluetoothState, client: RequestClient) -> Self {
        let factory = EffectFactory(state: state, client: client)
        return Effector(
            systemState: { try await factory.systemState(predicate: $0) },
            advertisement: { fatalError("Not implemented") },
            connect: { try await factory.connect(peripheral: $0) },
            disconnect: { _ in fatalError("Not implemented") },
            discoverServices: { _, _ in fatalError("Not implemented") },
            discoverCharacteristics: { _, _ in fatalError("Not implemented") },
            characteristicNotify: { _, _, _ in fatalError("Not implemented") },
            characteristicRead: { _, _ in fatalError("Not implemented") }
        )
    }
}

//public actor EffectFactory {
//    private let state: BluetoothState
//    private let client: RequestClient
//
//    private var promiseStore = PromiseStore<BluetoothEffect>()
//    private var isEnabled: Bool = false
//    private var scanningEnabled: Bool = false
//    private var scanningTasks: [Task<(), Never>] = []
//
//    public init(
//        state: BluetoothState,
//        client: RequestClient
//    ) {
//        self.state = state
//        self.client = client
//    }
//
//    // TODO: someone has to wire this up
//    func processDelegateEvent(_ event: DelegateEvent) async {
//        await updateState(for: event)
//        resolvePromises(for: event)
//    }
//
//    // MARK: - Effector
//
//    nonisolated func systemState(predicate: (@Sendable (SystemState) throws -> Bool)? = nil) async throws -> SystemStateEffect {
//        let currentState = await state.systemState
//        guard let predicate else {
//            return SystemStateEffect(currentState)
//        }
//        return Effect { [self] in
//            var result = SystemStateEffect(currentState)
//            while try predicate(result.systemState) == false {
//                result = try await self.awaitDelegateResponse(.systemState) { [client, needsEnable = !isEnabled] in
//                    // System state starts arriving via the delegate callback once we invoke enable
//                    if needsEnable {
//                        client.enable()
//                    }
//                }
//                try Task.checkCancellation()
//                await self.updateIsEnabled(true)
//            }
//            return result
//        }
//    }
//
//    nonisolated func connectEffect(peripheral: AnyPeripheral) -> Effect<PeripheralEffect> {
//        effect(.peripheral(.connect, peripheral)) { [client] in
//            client.connect(peripheral)
//        }
//    }
//
//    // MARK: - Private Logic
//
//    nonisolated func effect<T: BluetoothEffect>(
//        _ key: EffectKey,
//        launchEffect: @escaping @Sendable () -> Void
//    ) -> Effect<T> {
//        return Effect { [weak self] in
//            guard !Task.isCancelled else { throw BluetoothError.cancelled }
//            guard let self else { throw BluetoothError.unavailable }
//            return try await awaitDelegateResponse(key, launchEffect: launchEffect)
//        }
//    }
//
//    private func updateIsEnabled(_ isEnabled: Bool) {
//        self.isEnabled = isEnabled
//    }
//
//    private func awaitDelegateResponse<T: BluetoothEffect>(
//        _ key: EffectKey,
//        launchEffect: @Sendable () -> Void
//    ) async throws -> T {
//        let result = try await withCheckedThrowingContinuation { continuation in
//            promiseStore.register(continuation, with: key)
//            launchEffect()
//        }
//        try Task.checkCancellation()
//        guard let result = result as? T else {
//            throw BluetoothError.unknown // TODO: system error
//        }
//        return result
//    }
//
//    private func updateState(for event: DelegateEvent) async {
//        switch event {
//        case let .systemState(newState):
//            await state.setSystemState(newState)
//        default:
//            break
//        }
//    }
//
//    private func resolvePromises(for event: DelegateEvent) {
//        let effect = event.toEffect()
//        if let effect = effect as? ErrorEffect {
//            promiseStore.reject(with: effect.error, for: effect.key)
//        } else {
//            promiseStore.resolve(with: effect, for: effect.key)
//        }
//    }
//}

public actor EffectFactory: EffectorProtocol {
    private let state: BluetoothState
    private let client: RequestClient

    private var promiseStore = PromiseStore<BluetoothEffect>()
    private var isEnabled: Bool = false
    private var scanningEnabled: Bool = false
    private var scanningTasks: [Task<(), Never>] = []

    public init(
        state: BluetoothState,
        client: RequestClient
    ) {
        self.state = state
        self.client = client
    }

    // TODO: someone has to wire this up
    func processDelegateEvent(_ event: DelegateEvent) async {
        await updateState(for: event)
        resolvePromises(for: event)
    }

    // MARK: - Effector

    nonisolated func systemState(predicate: (@Sendable (SystemState) throws -> Bool)? = nil) async throws -> SystemStateEffect {
        var result = SystemStateEffect(await state.systemState)
        guard let predicate else { return result }
        while try predicate(result.systemState) == false {
            result = try await awaitDelegateResponse(.systemState) { [needsEnable = !isEnabled] in
                // System state starts arriving via the delegate callback once we invoke enable
                if needsEnable {
                    client.enable()
                }
            }
            try Task.checkCancellation()
            await setIsEnabled(true)
        }
        return result
    }

    nonisolated func advertisement() async throws -> AdvertisementEffect {
        try await awaitDelegateResponse(.advertisement) {
            // nothing to do here
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

    private func awaitDelegateResponse<T: BluetoothEffect>(
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

    private func setIsEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    private func updateState(for event: DelegateEvent) async {
        switch event {
        case let .systemState(newState):
            await state.setSystemState(newState)
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
}

extension PromiseStore {
    @inlinable
    mutating func register(_ continuation: CheckedContinuation<Result, any Error>, effect key: EffectKey) {
        register(continuation, with: key)
    }
}
