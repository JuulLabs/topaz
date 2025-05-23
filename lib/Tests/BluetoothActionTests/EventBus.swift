import EventBus

/**
 An event bus that automatically resolves pending requests with any event that arrives.
 */
func selfResolvingEventBus() async -> EventBus {
    let eventBus = EventBus()
    let key = EventBusListenerKey(listenerId: "test", filter: .unfiltered)
    await eventBus.attachGenericListener(listenerKey: key) { [weak eventBus] event in
        await eventBus?.resolvePendingRequests(for: event)
    }
    return eventBus
}
