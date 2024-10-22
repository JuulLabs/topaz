import Foundation

public typealias JsContextIdentifier = Int

/**
 Represents the communications channel to a web page javascript context.
 */
public struct JsContext: Sendable, Identifiable {
    public let id: JsContextIdentifier
    public let eventSink: EventSink

    public init(
        id: JsContextIdentifier
   ) {
       self.id = id
       self.eventSink = EventSink()
    }
}
