import Foundation
import JsMessage
import WebKit

/**
 Container for satisfying WKScriptMessageHandlerWithReply delegate plumbing.
 */
@MainActor
class ScriptHandler: NSObject {
    private let context: JsContext
    private let factory: JsMessageProcessorFactory
    private var cache: [String: JsMessageProcessor] = [:]

    init(context: JsContext, factory: JsMessageProcessorFactory) {
        self.context = context
        self.factory = factory
        super.init()
    }

    var allHandlerNames: [String] {
        factory.handlerNames
    }

    func getProcessor(named name: String) async -> JsMessageProcessor? {
        guard let processor = cache[name] else {
            if let newProcessor = factory.makeProcessor(name, context: context) {
                cache[name] = newProcessor
                await newProcessor.didAttach(to: context)
            }
            return cache[name]
        }
        return processor
    }

    func detachProcessors() {
        let processors = cache.values
        cache.removeAll()
        Task.detached { [context] in
            for processor in processors {
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
        if processor.enableDebugLogging {
            print("REQUEST \(message.name): \(message.body)")
        }
#endif
        let result = await processor.process(request: request, in: context)
#if DEBUG
        switch result {
        case let .body(value):
            if processor.enableDebugLogging {
                print("RESPONSE \(message.name): \(value.jsValue)")
            }
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
