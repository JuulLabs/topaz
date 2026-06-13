import Foundation
import JsMessage
import Observation
import OSLog

private let messageLog = Logger(subsystem: "Topaz", category: "AppMessage")

public final actor AppMessageProcessor: JsMessageProcessor {
    public static let handlerName = "topaz"
    public let enableDebugLogging: Bool

    private let host: AppMessageHost

    public init(
        host: AppMessageHost,
        enableDebugLogging: Bool = false
    ) {
        self.host = host
        self.enableDebugLogging = enableDebugLogging
    }

    public func didAttach(to context: JsContext) async {
    }

    public func didDetach(from context: JsContext) async {
    }

    public func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse {
        var actionForFailureLogging: Message.Action?
        do {
            let message = try request.extractMessage().get()
            actionForFailureLogging = message.action
            logRequest(message: message)
            let response = try await processAction(message: message)
            logResponse(action: message.action, response: response)
            return response
        } catch {
            let response = JsMessageResponse.error(error.toDomError())
            logResponse(action: actionForFailureLogging, response: response)
            return response
        }
    }

    private func processAction(message: Message) async throws -> JsMessageResponse {
        switch message.action {
        case .setUserAgentMode:
            await setUserAgentAction(messageData: message.bodyData)
        }
    }

    private func setUserAgentAction(messageData: [String: JsType]?) async -> JsMessageResponse {
        guard let userAgentMode = messageData?["mode"]?.string else {
            return .error(AppMessageError.badRequest.toDomError())
        }
        guard await host.setUserAgentMode(userAgentMode) else {
            return .error(AppMessageError.userAgentModeChangeFailed.toDomError())
        }
        return .body([:])
    }

    private func logRequest(message: Message) {
        guard enableDebugLogging else { return }
        messageLog.debug("Request \(message.action.rawValue, privacy: .public): \(JsType.dictionaryAsString(message.bodyData), privacy: .public)")
    }

    private func logResponse(action: Message.Action?, response: JsMessageResponse) {
        guard enableDebugLogging else { return }
        let actionString = action?.rawValue ?? "?"
        switch response {
        case let .body(body):
            messageLog.debug("Response \(actionString, privacy: .public): \(body.asDebugString(), privacy: .public)")
        case let .error(error):
            messageLog.error("Response \(actionString, privacy: .public): \(error.jsRepresentation, privacy: .public)")
        }
    }
}
