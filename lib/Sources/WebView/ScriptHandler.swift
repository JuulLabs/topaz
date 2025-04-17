import Bluetooth
import BluetoothEngine
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
    private let authorize: () async -> Bool
    private var cache: [String: JsMessageProcessor] = [:]

    init(context: JsContext, factory: JsMessageProcessorFactory, authorize: @escaping () async -> Bool) {
        self.context = context
        self.factory = factory
        self.authorize = authorize
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

    func userDidAuthorize(handlerName: String) async -> Bool {
        guard handlerName == BluetoothEngine.handlerName else { return true }
        return await authorize()
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
        guard await userDidAuthorize(handlerName: request.handlerName) else {
            return (nil, BluetoothError.unauthorized.toDomError().jsRepresentation)
        }
        let result = await processor.process(request: request, in: context)
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
