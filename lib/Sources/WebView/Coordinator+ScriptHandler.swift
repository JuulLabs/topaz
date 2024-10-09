import Foundation
import WebKit

extension Coordinator: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("userContentController.didReceiveMessage: \(message.name)")
    }
}

extension Coordinator: WKScriptMessageHandlerWithReply {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        print("userContentController.didReceiveMessage: \(message.name)")
        return (nil, nil)
    }
}
