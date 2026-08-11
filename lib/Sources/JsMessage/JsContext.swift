import Foundation

/**
 Represents the communications channel to a web page javascript context.
 */
public struct JsContext: Sendable, Identifiable {
    public let id: JsContextIdentifier
    private let eventSink: @MainActor (JsEvent) async -> Result<Void, any Error>
    private let deliveryBarrier: @MainActor () async -> Void

    public init(
        id: JsContextIdentifier,
        eventSink: @escaping @MainActor (JsEvent) async -> Result<Void, any Error>,
        awaitPendingDeliveries: @escaping @MainActor () async -> Void = {}
    ) {
        self.id = id
        self.eventSink = eventSink
        self.deliveryBarrier = awaitPendingDeliveries
    }

    public func sendEvent(_ event: JsEvent) async -> Result<Void, any Error> {
        await eventSink(event)
    }

    /// Waits for events already handed to `sendEvent` to reach the page. Accepting an
    /// event does not deliver it, so a reply whose meaning depends on its event having
    /// landed first - a characteristic read, whose value the page takes from the event -
    /// must wait here before it is sent.
    public func awaitPendingDeliveries() async {
        await deliveryBarrier()
    }
}
