
public struct EventBusListenerKey: Sendable, Hashable {
    public enum EventFilter: Sendable, Hashable {
        case unfiltered
    }

    public let listenerId: String
    public let filter: EventFilter

    public init(listenerId: String, filter: EventFilter) {
        self.listenerId = listenerId
        self.filter = filter
    }
}
