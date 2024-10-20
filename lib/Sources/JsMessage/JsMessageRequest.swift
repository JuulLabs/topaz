import Foundation

/**
 WKScriptMessageHandlerWithReply delegate request data.
 */
public struct JsMessageRequest: Sendable {
    public let handlerName: String
    public let body: [String: JsType]

    public init(handlerName: String, body: Dictionary<String, JsType>) {
        self.handlerName = handlerName
        self.body = body
    }
}
