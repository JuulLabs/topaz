/// A `JsMessageProcessor` that decodes the incoming request into a typed action message and
/// dispatches it to `handle(_:)`.
public protocol DispatchingJsMessageProcessor: JsMessageProcessor {
    associatedtype Action: JsMessageAction
    var messageLog: JsMessageLog { get }
    func handle(_ message: JsActionMessage<Action>) async throws -> JsMessageResponse
}

extension DispatchingJsMessageProcessor {
    public func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse {
        var actionForFailureLogging: Action?
        do {
            let message: JsActionMessage<Action> = try request.extractMessage().get()
            actionForFailureLogging = message.action
            messageLog.logRequest(action: message.action.rawValue, body: message.bodyData)
            let response = try await handle(message)
            messageLog.logResponse(action: message.action.rawValue, response)
            return response
        } catch {
            let response = JsMessageResponse.error(error.toDomError())
            messageLog.logResponse(action: actionForFailureLogging?.rawValue, response)
            return response
        }
    }
}
