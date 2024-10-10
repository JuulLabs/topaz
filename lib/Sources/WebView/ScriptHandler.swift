import Foundation
import WebKit

class ScriptHandler: NSObject {
    let name: String

    var process: (_ request: ScriptMessageRequest) -> Void = { _ in fatalError() }
    var processForReply: (_ request: ScriptMessageRequest) async -> ScriptMessageResponse = { _ in fatalError() }

    init(name: String) {
        self.name = name
    }
}

extension ScriptHandler: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let request = message.toRequest() else { return }
        process(request)
    }
}

extension ScriptHandler: WKScriptMessageHandlerWithReply {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard let request = message.toRequest() else {
            return (nil, "Unrecognized message")
        }
        return switch await processForReply(request) {
        case let .body(value):
            (value.jsValue, nil)
        case let .error(reason):
            (nil, reason)
        }
    }
}

extension WKScriptMessage {
    func toRequest() -> ScriptMessageRequest? {
        guard let dictionary = JsType.bridgeOrNull(body)?.dictionary else { return .none }
        return ScriptMessageRequest(name: name, body: dictionary)
    }
}
