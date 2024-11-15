import Bluetooth

/**
 Provides a mechanism to play effects against the bluetooth system with a direct call
 interface. Effects are suspended in a continuation until the corresponding delegate
 event is received and mediated back to the caller via the promise store.
 */
public actor EventService {
    private var promiseStore: PromiseStore<BluetoothEvent> = .init()

    public init() {
    }

    public func handleEvent(_ event: BluetoothEvent) {
        resolvePromises(for: event)
    }

    public func cancelAllEvents(with error: any Error) {
        promiseStore.rejectAll(with: error)
    }

    public func awaitEvent<T: BluetoothEvent>(
        key: EventKey,
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

    private func resolvePromises(for event: BluetoothEvent) {
        if let event = event as? ErrorEvent {
            promiseStore.reject(with: event.error, for: event.key)
        } else {
            promiseStore.resolve(with: event, for: event.key)
        }
    }
}
