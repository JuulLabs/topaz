import Foundation

public protocol JsMessageRequestDecodable {
    static func decode(from message: JsMessageRequest) -> Self?
}

public protocol JsMessageResponseEncodable {
    func encode() -> JsMessageResponse
}
