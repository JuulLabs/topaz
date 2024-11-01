import Foundation
import JsMessage
import WebKit

/**
 Container for satisfying WKScriptMessageHandlerWithReply delegate plumbing.
 */
@MainActor
class ScriptHandler: NSObject {
    private let context: JsContext
    private let processors: [String: JsMessageProcessor]
    private var notifiedProcessors: Set<String> = []

    init(context: JsContext, processors: [JsMessageProcessor]) {
        self.context = context
        self.processors = processors.reduce(into: [:]) { lookupTable, processor in
            lookupTable[processor.handlerName] = processor
        }
        super.init()
    }

    var allProcessors: Dictionary<String, any JsMessageProcessor>.Values {
        processors.values
    }

    func getProcessor(named name: String) async -> JsMessageProcessor? {
        guard let processor = processors[name] else {
            return nil
        }
        if !notifiedProcessors.contains(name) {
            notifiedProcessors.insert(name)
            await processor.didAttach(to: context)
        }
        return processor
    }

    func detachProcessors() {
        let detached = processors.reduce(into: [JsMessageProcessor]()) { (result, entry) in
            if notifiedProcessors.contains(entry.key) {
                result.append(entry.value)
            }
        }
        Task.detached { [context, detached] in
            for processor in detached {
                await processor.didDetach(from: context)
            }
        }
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
            (nil, reason.jsRepresentation)
        }
    }
}

extension WKScriptMessage {
    func toRequest() -> JsMessageRequest? {
        guard let dictionary = JsType.bridgeOrNull(body)?.dictionary else { return .none }
        return JsMessageRequest(handlerName: name, body: dictionary)
    }
}
