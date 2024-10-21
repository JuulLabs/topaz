import BluetoothClient
import Foundation
import WebKit

@MainActor
public class Coordinator: NSObject {

    override init() {}

    func initialize(webView: WKWebView, model: WebPageModel, engine: BluetoothEngine) {
        webView.customUserAgent = model.customUserAgent
        webView.navigationDelegate = self

        // TODO: offload this to be async and show a loading indicator
        let bluetoothHandler = constructBluetoothHandler(id: model.nodeId, engine: engine)
        webView.loadHandlers([bluetoothHandler])
        webView.loadScripts(["BluetoothPolyfill"])
    }

    func deinitialize(webView: WKWebView) {
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.configuration.userContentController.removeAllUserScripts()
    }

    func update(webView: WKWebView, model: WebPageModel) {
        // TODO: load when observed model url changes only
        webView.load(URLRequest(url: model.url))
    }
}

extension WKWebView {
    func loadHandlers(_ handlers: [ScriptHandler]) {
        handlers.forEach { handler in
            configuration.userContentController.addScriptMessageHandler(handler, contentWorld: .page, name: handler.name)
        }
    }

    func loadScripts(_ scripts: [String]) {
        scripts.forEach { name in
            if let resource = loadJsResource(name) {
                let script = WKUserScript(source: resource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
                configuration.userContentController.addUserScript(script)
            } else {
                fatalError("Missing resource \(name)")
            }
        }
    }
}

private func loadJsResource(_ name: String) -> String? {
    guard let fileURL = Bundle.module.url(forResource: name, withExtension: "js") else {
        return nil
    }
    return try? String(contentsOf: fileURL)
}

// TODO: relocate this to own module
private func constructBluetoothHandler(id: WebNodeIdentifier, engine: BluetoothEngine) -> ScriptHandler {
    let node = WebNode(id: id) { @MainActor _ in
        // TODO: wire up Js out-of-band event injection here
        // probably something like `evaluateJavascript(blah)`
    }
    let handler = ScriptHandler(name: "bluetooth")
    handler.process = { request in
        guard let action = request.toEngineRequest() else {
            // TODO: log and ignore
            fatalError("bad request")
        }
        await engine.perform(action: action, for: node)
    }
    handler.processForReply = { webRequest in
        guard let request = webRequest.toEngineRequest() else {
            return .error("Bad request")
        }
        let response = await engine.process(request: request, for: node)
        return response.toScriptResponse()
    }
    return handler
}

extension ScriptMessageRequest {
    // TODO: define a messaging protocol for the Javascript context communication pipe
    func toEngineRequest() -> WebBluetoothRequest? {
        // TODO: just to get things going until we get a protocol in place
        // Web page sends {"action":"getAvailability"} and we reply with {"isAvailable":true/false}
        switch body["action"]?.string {
        case .some("getAvailability"):
            .getAvailability
        default:
            nil
        }
    }
}

extension WebBluetoothResponse {
    func toScriptResponse() -> ScriptMessageResponse {
        switch self {
        case let .availability(isAvailable):
            .body(["isAvailable": isAvailable])
        default:
            fatalError("remove me: case should be exhaustive")
        }
    }
}
