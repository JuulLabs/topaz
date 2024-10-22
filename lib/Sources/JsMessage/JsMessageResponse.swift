import Foundation

/**
 WKScriptMessageHandlerWithReply delegate response data.
 */
public enum JsMessageResponse: Sendable {
    case body(JsConvertable)
    case error(String)
}
