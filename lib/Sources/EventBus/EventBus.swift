import Bluetooth
import JsMessage
import OSLog

private let eventLog = Logger(subsystem: "EventBus", category: "Event")

public actor EventBus {
    private enum StaticPromiseKey { case allEvents }

    private let enableDebugLogging: Bool
    private var promiseStore: PromiseStore<BluetoothEvent>
    private var listenerStore: ListenerStore<BluetoothEvent>
    private let eventQueue: AsyncStream<BluetoothEvent>.Continuation
    private var jsContext: JsContext?

    public init(
        enableDebugLogging: Bool = false
    ) {
        self.enableDebugLogging = enableDebugLogging
        self.promiseStore = .init()
        self.listenerStore = .init()
        let (stream, contination) = AsyncStream<BluetoothEvent>.makeStream()
        self.eventQueue = contination
        Task { [weak self] in
            for await event in stream {
                await self?.emitEvent(event)
            }
        }
    }

    deinit {
        eventQueue.finish()
    }

    public func setJsContext(_ context: JsContext?) {
        self.jsContext = context
    }

    /**
     Enqueue an event for emission. Invokes `emitEvent` on a dedicated task in order of arrival.
     */
    public nonisolated func enqueueEvent(_ event: any BluetoothEvent) {
        eventQueue.yield(event)
    }

    /**
     Forward an event to all listsners.
     */
    public func emitEvent(_ event: any BluetoothEvent) async {
        await emitEventToGenericListeners(event)
        await emitEventToKeyedListeners(event)
    }

    /**
     Submit an event to unblock any awaiting operations.
     */
    public func resolvePendingRequests(for event: BluetoothEvent) {
        if let event = event as? ErrorEvent {
            rejectPromises(with: event.error, lookup: event.lookup)
        } else {
            resolvePromises(with: event, lookup: event.lookup)
        }
    }

    /**
     Forward an event to the Javascript event handler if there is one.
     */
    @discardableResult
    public nonisolated func sendJsEvent(_ jsEvent: JsEvent) async -> Result<Void, any Error> {
        guard let context = await self.jsContext else {
            // The web page probably went away or is in the process of being torn down
            return .failure(EventBusError.jsContextUnavailable)
        }
        if enableDebugLogging {
            eventLog.debug("Event \(jsEvent.eventName, privacy: .public): \(jsEvent.asDebugString(), privacy: .public)")
        }
        let result = await context.sendEvent(jsEvent)
        if case let .failure(error) = result {
            eventLog.error("Event send failed \(jsEvent.eventName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
        return result
    }

    /**
     Cancel all pending operations that are awaiting on events and detach all listeners.
     */
    public func cancelEverything(with error: any Error) {
        promiseStore.rejectAll(with: error)
        listenerStore.detachAll()
    }

    /**
     Blocks (yields) in a continuation waiting for an event matching the given key to arrive.
     The provided effect closure will be executed synchronously after the continuation is registered,
     but before yielding to receive events. May throw if a matching error event arrives or if cancelled.
     */
    @discardableResult
    public func awaitEvent<T: BluetoothEvent>(
        forKey key: EventRegistrationKey,
        launchEffect: @Sendable () -> Void = {}
    ) async throws -> T {
        let result = try await withCheckedThrowingContinuation { continuation in
            promiseStore.register(continuation, with: key)
            launchEffect()
        }
        try Task.checkCancellation()
        guard let result = result as? T else {
            throw EventBusError.typeMismatch(key.name, expectedType: "\(type(of: T.self))")
        }
        return result
    }

    /**
     Invokes `awaitEvent(forkey:)` repeatedly until the given predicate is satisfied or an error is thrown.
     */
    @discardableResult
    public func awaitEvent<T: BluetoothEvent>(
        forKey key: EventRegistrationKey,
        where predicate: (T) throws -> Bool
    ) async throws -> T {
        var result: T
        repeat {
            result = try await awaitEvent(forKey: key)
        } while try predicate(result) == false
        return result
    }

    /**
     Attach a general listener for non-specific events and/or errors. Remains attached until explicitly
     removed. Use this to attach middleware that needs to monitor system activity.
     */
    public func attachGenericListener(
        listenerKey: EventBusListenerKey,
        onEvent: @Sendable @escaping (any BluetoothEvent) async -> Void
    ) {
        listenerStore.attach(key: listenerKey, block: onEvent)
    }

    /**
     Attach a self-terminating listener for events matching the given event key.
     When an error event arrives it is forwarded to `onEvent` as a failure and then the listener is automatically detached.
     */
    public func attachEventListener<T: BluetoothEvent>(
        forKey key: EventRegistrationKey,
        onEvent: @Sendable @escaping (Result<T, any Error>) async -> Void
    ) {
        listenerStore.attach(key: key) { event in
            await onEvent(event.toResult(expectedEventName: key.name))
        }
    }

    /**
     Detach any event listener(s) matching the given identifier.
     */
    public func detachListener(forKey key: AnyHashable) {
        listenerStore.detach(key: key)
    }

    /**
     Detach all event listener(s).
     */
    public func detachAllListeners() {
        listenerStore.detachAll()
    }

    private func emitEventToGenericListeners(_ event: BluetoothEvent) async {
        let genericListeners = listenerStore.getListeners { (key: EventBusListenerKey) in
            switch key.filter {
            case .unfiltered:
                true
            }
        }
        for listener in genericListeners {
            await listener(event)
        }
    }

    private func emitEventToKeyedListeners(_ event: BluetoothEvent) async {
        let listeners = switch event.lookup.match {
        case let .exact(key):
            if event is ErrorEvent {
                listenerStore.detachListeners(forKey: key)
            } else {
                listenerStore.getListeners(forKey: key)
            }
        case let .wildcard(name, attributes):
            if event is ErrorEvent {
                listenerStore.detachListeners(where: attributes.predicate(name: name))
            } else {
                listenerStore.getListeners(where: attributes.predicate(name: name))
            }
        }
        for listener in listeners {
            await listener(event)
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

private extension BluetoothEvent {
    func toResult<T: BluetoothEvent>(expectedEventName: EventName) -> Result<T, any Error> {
        switch self {
        case let self as T:
            .success(self)
        case let self as ErrorEvent:
            .failure(self.error)
        default:
            .failure(EventBusError.typeMismatch(expectedEventName, expectedType: "\(type(of: T.self))"))
        }
    }
}
