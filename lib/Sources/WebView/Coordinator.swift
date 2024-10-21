import BluetoothClient
import Foundation
import JsMessage
import WebKit

@MainActor
public class Coordinator: NSObject {

    override init() {}

    func initialize(webView: WKWebView, model: WebPageModel) {
        webView.customUserAgent = model.customUserAgent
        webView.navigationDelegate = self

        let context = JsContext(id: model.contextId)
        let scriptHandler = ScriptHandler(context: context)
        model.messageProcessors.forEach( { processor in
            scriptHandler.attach(processor: processor)
        })
        webView.attachScriptHandler(scriptHandler)

        // TODO: offload this to be async and show a loading indicator
        webView.loadScripts(model.scriptResourceNames)
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
    func attachScriptHandler(_ handler: ScriptHandler) {
        handler.allProcessors.forEach { processor in
            configuration.userContentController.addScriptMessageHandler(handler, contentWorld: .page, name: processor.handlerName)
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
