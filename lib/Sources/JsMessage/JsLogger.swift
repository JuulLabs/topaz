
public final class JsLogger: JsMessageProcessor {
    public static let handlerName = "logging"
    public let enableDebugLogging = false

    public init() {}

    public func didAttach(to context: JsContext) async {
        // no-op
    }

    public func didDetach(from context: JsContext) async {
        // no-op
    }

    public func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse {
        guard let message = request.body["msg"]?.string else {
            return .error(DomError(name: .encoding, message: "Log body missing required field 'msg'"))
        }
        // For now just use the console for debug logging
        print("JsLog: \(message)")
        return .body([:])
    }
}
