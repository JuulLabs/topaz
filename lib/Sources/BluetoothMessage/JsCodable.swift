import JsMessage

public protocol JsMessageDecodable: Sendable {
    static func decode(from data: [String: JsType]?) -> Self?
}

extension JsMessageDecodable {
    public static func decode(from message: Message) -> Result<Self, Error> {
        return message.decode(Self.self)
    }
}

public protocol JsMessageEncodable: Sendable {
    func toJsMessage() -> JsMessageResponse
}

public protocol JsEventEncodable: Sendable {
    func toJsEvent() -> JsEvent
}
