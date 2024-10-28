import JsMessage

protocol JsMessageDecodable {
    associatedtype Request
    static func decode(from data: [String: JsType]?) -> Request?
}

extension JsMessageDecodable {
    static func decode(from message: Message) -> Result<Request, Error> {
        return message.decode(Self.self)
    }
}

protocol JsMessageEncodable: Sendable {
    func toJsMessage() -> JsMessageResponse
}

protocol JsEventEncodable: Sendable {
    func toJsEvent() -> JsEvent
}
