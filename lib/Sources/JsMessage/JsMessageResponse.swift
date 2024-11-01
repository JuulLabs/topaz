import Foundation

/**
 WKScriptMessageHandlerWithReply delegate response data.
 */
public enum JsMessageResponse: Sendable {
    case body(JsConvertable)
    case error(JsErrorStringRepresentable)
}

public protocol JsErrorStringRepresentable: Sendable {
    var jsRepresentation: String { get }
}
