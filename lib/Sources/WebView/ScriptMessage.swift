import Foundation

/**
 WKScriptMessageHandlerWithReply delegate request data.
 */
struct ScriptMessageRequest: Sendable {
    let name: String
    let body: [String: JsType]
}

/**
 WKScriptMessageHandlerWithReply delegate response data.
 */
enum ScriptMessageResponse: Sendable {
    case body(JsConvertable)
    case error(String)
}
