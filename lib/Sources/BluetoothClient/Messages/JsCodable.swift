import JsMessage

protocol JsMessageDecodable {
    static func decode(from data: [String: JsType]?) -> Self?
}

extension JsMessageDecodable {
    static func decode(from message: Message) -> Result<Self, Error> {
        return message.decode(Self.self)
    }
}

protocol JsMessageEncodable: Sendable {
    func toJsMessage() -> JsMessageResponse
}

protocol JsEventEncodable: Sendable {
    func toJsEvent() -> JsEvent
}
