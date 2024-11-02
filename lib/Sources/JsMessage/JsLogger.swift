
public let jsLogger: JsMessageProcessor = JsLogger()

final class JsLogger: JsMessageProcessor {
    let handlerName = "logging"

    func didAttach(to context: JsContext) async {
        // no-op
    }

    func didDetach(from context: JsContext) async {
        // no-op
    }

    func process(request: JsMessageRequest) async -> JsMessageResponse {
        guard let message = request.body["msg"]?.string else {
            return .error(DomError(name: .encoding, message: "Log body missing required field 'msg'"))
        }
        // For now just use the console for debug logging
        print("JsLog: \(message)")
        return .body([:])
    }
}
