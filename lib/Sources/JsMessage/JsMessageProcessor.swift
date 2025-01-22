import Foundation

/**
 WKScriptMessageHandlerWithReply delegate message handler.
 */
public protocol JsMessageProcessor: Sendable {
    // Referenced in Javascript as `window.webkit.messageHandlers.<handlerName>`
    static var handlerName: String { get }
    var enableDebugLogging: Bool { get }
    func didAttach(to context: JsContext) async
    func didDetach(from context: JsContext) async
    func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse
}
