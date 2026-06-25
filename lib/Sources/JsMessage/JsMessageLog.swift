import OSLog

/// Shared request/response debug logging for `JsMessageProcessor` conformances.
public struct JsMessageLog: Sendable {
    private let logger: Logger
    private let isEnabled: Bool

    public init(logger: Logger, enabled: Bool) {
        self.logger = logger
        self.isEnabled = enabled
    }

    public func logRequest(action: String, body: [String: JsType]?) {
        guard isEnabled else { return }
        logger.debug("Request \(action, privacy: .public): \(JsType.dictionaryAsString(body), privacy: .public)")
    }

    public func logResponse(action: String?, _ response: JsMessageResponse) {
        guard isEnabled else { return }
        let actionString = action ?? "?"
        switch response {
        case let .body(body):
            logger.debug("Response \(actionString, privacy: .public): \(body.asDebugString(), privacy: .public)")
        case let .error(error):
            logger.error("Response \(actionString, privacy: .public): \(error.jsRepresentation, privacy: .public)")
        }
    }

    public func logEvent(_ event: JsEvent) {
        guard isEnabled else { return }
        logger.debug("Event: \(event.asDebugString(), privacy: .public)")
    }
}
