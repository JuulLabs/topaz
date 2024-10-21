import Foundation
import JsMessage
import WebKit

/**
 Container for satisfying WKScriptMessageHandlerWithReply delegate plumbing.
 */
@MainActor
class ScriptHandler: NSObject {
    let context: JsContext

    private var processors: [String: JsMessageProcessor] = [:]
    private var alreadyAttached: Set<String> = []

    init(context: JsContext) {
        self.context = context
        super.init()
        self.attach(processor: context.eventSink)
    }

    var allProcessors: Dictionary<String, any JsMessageProcessor>.Values {
        processors.values
    }

    func attach(processor: JsMessageProcessor) {
        processors[processor.handlerName] = processor
    }

    // TODO: detach processors when webview goes out of scope

    func getProcessor(named name: String) async -> JsMessageProcessor? {
        guard let processor = processors[name] else {
            return nil
        }
        if !alreadyAttached.contains(name) {
            alreadyAttached.insert(name)
            await processor.didAttach(to: context)
        }
        return processor
    }
}

extension ScriptHandler: WKScriptMessageHandlerWithReply {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard let request = message.toRequest() else {
            return (nil, "Unrecognized message")
        }
        guard let processor = await getProcessor(named: request.handlerName) else {
            return (nil, "Handler not found for \(request.handlerName)")
        }
#if DEBUG
        print("REQUEST \(message.name): \(message.body)")
#endif
        let result = await processor.process(request: request)
#if DEBUG
        switch result {
        case let .body(value):
            print("RESPONSE \(message.name): \(value.jsValue)")
        case let .error(reason):
            print("RESPONSE \(message.name) ERROR: \(reason)")
        }
#endif
        return switch result {
        case let .body(value):
            (value.jsValue, nil)
        case let .error(reason):
            (nil, reason)
        }
    }
}

extension WKScriptMessage {
    func toRequest() -> JsMessageRequest? {
        guard let dictionary = JsType.bridgeOrNull(body)?.dictionary else { return .none }
        return JsMessageRequest(handlerName: name, body: dictionary)
    }
}
