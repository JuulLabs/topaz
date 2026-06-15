import Foundation
import JsMessage
import Observation
import OSLog

private let logger = Logger(subsystem: "Topaz", category: "AppMessage")

public final actor AppMessageProcessor: DispatchingJsMessageProcessor {

    public enum Action: String, JsMessageAction {
        case setUserAgentMode
    }

    public static let handlerName = "topaz"
    public let enableDebugLogging: Bool
    public let messageLog: JsMessageLog

    private let host: AppMessageHost

    public init(
        host: AppMessageHost,
        enableDebugLogging: Bool = false
    ) {
        self.host = host
        self.enableDebugLogging = enableDebugLogging
        self.messageLog = JsMessageLog(logger: logger, enabled: enableDebugLogging)
    }

    public func didAttach(to context: JsContext) async {
    }

    public func didDetach(from context: JsContext) async {
    }

    public func handle(_ message: JsActionMessage<Action>) async throws -> JsMessageResponse {
        switch message.action {
        case .setUserAgentMode:
            await setUserAgentAction(messageData: message.bodyData)
        }
    }

    private func setUserAgentAction(messageData: [String: JsType]?) async -> JsMessageResponse {
        guard let userAgentMode = messageData?["mode"]?.string else {
            return .error(JsMessageError.badRequest.toDomError())
        }
        guard await host.setUserAgentMode(userAgentMode) else {
            return .error(AppMessageError.userAgentModeChangeFailed.toDomError())
        }
        return .body([:])
    }
}
