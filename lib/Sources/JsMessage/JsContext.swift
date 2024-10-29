import Foundation

/**
 Represents the communications channel to a web page javascript context.
 */
public struct JsContext: Sendable, Identifiable {
    public let id: JsContextIdentifier
    private let eventSink: @MainActor (JsEvent) -> Void

    public init(
        id: JsContextIdentifier,
        eventSink: @escaping @MainActor (JsEvent) -> Void
    ) {
        self.id = id
        self.eventSink = eventSink
    }

    public func sendEvent(_ event: JsEvent) async {
        await eventSink(event)
    }
}
