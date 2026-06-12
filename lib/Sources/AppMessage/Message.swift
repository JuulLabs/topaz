import JsMessage

struct Message {
    enum Action: String, CaseIterable {
        case setUserAgentMode
    }

    let action: Action
    private let requestBody: [String: JsType]

    var bodyData: [String: JsType]? {
        requestBody["data"]?.dictionary
    }

    init(action: Action, requestBody: [String: JsType] = [:]) {
        self.action = action
        self.requestBody = requestBody
    }
}

extension JsMessageRequest {
    func extractMessage() -> Result<Message, any Error> {
        guard let actionString = body["action"]?.string else {
            return .failure(AppMessageError.badRequest)
        }
        guard let action = Message.Action.from(string: actionString) else {
            return .failure(AppMessageError.actionNotFound(actionString))
        }
        return .success(Message(action: action, requestBody: body))
    }
}

fileprivate extension Message.Action {
    static func from(string: String) -> Message.Action? {
        allCases.first(where: { $0.rawValue == string })
    }
}
