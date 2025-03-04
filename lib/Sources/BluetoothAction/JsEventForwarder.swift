import JsMessage

public struct JsEventForwarder: Sendable {
    let forwardEvent: @Sendable (JsEvent) async -> Void

    public init(forwardEvent: @Sendable @escaping (JsEvent) async -> Void) {
        self.forwardEvent = forwardEvent
    }
}
