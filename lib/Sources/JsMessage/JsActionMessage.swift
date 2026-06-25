import Foundation

/// A generic, decoded JS message: an `action` plus the raw request `data` body.
public struct JsActionMessage<Action: JsMessageAction>: Sendable {
    public let action: Action
    public let requestBody: [String: JsType]

    public var bodyData: [String: JsType]? {
        requestBody["data"]?.dictionary
    }

    public init(action: Action, requestBody: [String: JsType] = [:]) {
        self.action = action
        self.requestBody = requestBody
    }
}

extension JsMessageRequest {
    public func extractMessage<Action: JsMessageAction>() -> Result<JsActionMessage<Action>, any Error> {
        guard let actionString = body["action"]?.string else {
            return .failure(JsMessageError.badRequest)
        }
        guard let action = Action(rawValue: actionString) else {
            return .failure(JsMessageError.actionNotFound(actionString))
        }
        return .success(JsActionMessage(action: action, requestBody: body))
    }
}
