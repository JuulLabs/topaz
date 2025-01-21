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
        key: EventRegistrationKey,
        launchEffect: @Sendable () -> Void
    ) async throws -> T {
        let result = try await withCheckedThrowingContinuation { continuation in
            promiseStore.register(continuation, with: key)
            launchEffect()
        }
        try Task.checkCancellation()
        guard let result = result as? T else {
            throw EventServiceError.typeMismatch(key.name, expectedType: "\(type(of: T.self))")
        }
        return result
    }

    private func resolvePromises(for event: BluetoothEvent) {
        if let event = event as? ErrorEvent {
            rejectPromises(with: event.error, lookup: event.lookup)
        } else {
            resolvePromises(with: event, lookup: event.lookup)
        }
    }

    private func resolvePromises(with event: BluetoothEvent, lookup: EventLookup) {
        switch lookup.match {
        case let .exact(key):
            promiseStore.resolve(with: event, for: key)
        case let .wildcard(name, attributes):
            promiseStore.resolve(with: event, where: attributes.predicate(name: name))
        }
    }

    private func rejectPromises(with error: any Error, lookup: EventLookup) {
        switch lookup.match {
        case let .exact(key):
            promiseStore.reject(with: error, for: key)
        case let .wildcard(name, attributes):
            promiseStore.reject(with: error, where: attributes.predicate(name: name))
        }
    }
}
