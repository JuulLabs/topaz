import Foundation

/**
 Represents the communications channel to a web page javascript context.
 */
public struct JsContext: Sendable, Identifiable {
    public let id: JsContextIdentifier
    private let eventSink: @MainActor (JsEvent) async -> Result<Void, any Error>

    public init(
        id: JsContextIdentifier,
        eventSink: @escaping @MainActor (JsEvent) async -> Result<Void, any Error>
    ) {
        self.id = id
        self.eventSink = eventSink
    }

    public func sendEvent(_ event: JsEvent) async -> Result<Void, any Error> {
        await eventSink(event)
    }
}
