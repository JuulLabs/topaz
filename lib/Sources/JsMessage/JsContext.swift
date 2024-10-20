
public typealias JsContextIdentifier = Int

/**
 Represents the communications channel to a web page javascript context.
 */
public struct JsContext: Sendable, Identifiable {
    public let id: JsContextIdentifier
    public let sendEvent: @MainActor @Sendable (_ event: JsEvent) async -> Void

    public init(
        id: JsContextIdentifier,
        sendEvent: @MainActor @Sendable @escaping (_ event: JsEvent) async -> Void
    ) {
        self.id = id
        self.sendEvent = sendEvent
    }
}
