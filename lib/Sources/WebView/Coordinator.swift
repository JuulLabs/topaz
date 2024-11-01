import BluetoothClient
import Foundation
import JsMessage
import WebKit

@MainActor
public class Coordinator: NSObject {
    private let world: WKContentWorld = .page
    private var messageProcessors: [JsMessageProcessor]!
    private var contextId: JsContextIdentifier!
    private var scriptHandler: ScriptHandler?

    var navigatingToUrl: URL?

    override init() {}

    func initialize(webView: WKWebView, model: WebPageModel) {
        self.messageProcessors = model.messageProcessors
        self.contextId = JsContextIdentifier(tab: model.tab, url: model.url)

        webView.customUserAgent = model.customUserAgent
        webView.navigationDelegate = self

        // TODO: offload this to be async and show a loading indicator
        webView.loadScripts(model.scriptResourceNames)
    }

    func deinitialize(webView: WKWebView) {
        detachOldHandler(from: webView)
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.configuration.userContentController.removeAllUserScripts()
    }

    func update(webView: WKWebView, model: WebPageModel) {
        // TODO: load when observed model url changes only
        webView.load(URLRequest(url: model.url))
    }

    func attachNewHandler(to webView: WKWebView) {
        let context = webView.createContext(contextId: contextId, world: world)
        let newHandler = ScriptHandler(context: context, processors: messageProcessors)
        self.scriptHandler = newHandler
        webView.attachScriptHandler(newHandler, in: world)
    }

    func detachOldHandler(from webView: WKWebView) {
        guard let scriptHandler else { return }
        scriptHandler.detachProcessors()
        webView.detachScriptHandler(scriptHandler, in: world)
    }

    func didBeginNavigation(to url: URL, in webView: WKWebView) {
        detachOldHandler(from: webView)
        self.contextId = contextId.withUrl(url)
        attachNewHandler(to: webView)
        // TODO: tell model url changed without reloading it
    }
}

extension WKWebView {
    func createContext(contextId: JsContextIdentifier, world: WKContentWorld) -> JsContext {
        return JsContext(id: contextId) { [weak self] event in
            self?.callAsyncJavaScript(
                "topaz.sendEvent(event)",
                arguments: [ "event": event.jsValue ],
                in: nil,
                in: world) { result in
#if DEBUG
                    switch result {
                    case .success:
                        print("Did send event \(event.jsValue)")
                    case let .failure(error):
                        // TODO: log this somewhere
                        print("Event send failed: \(error.localizedDescription)")
                    }
#endif
            }
        }
    }

    func detachScriptHandler(_ handler: ScriptHandler, in world: WKContentWorld) {
        handler.allProcessors.forEach { processor in
            configuration.userContentController.removeScriptMessageHandler(forName: processor.handlerName, contentWorld: world)
        }
    }

    func attachScriptHandler(_ handler: ScriptHandler, in world: WKContentWorld) {
        handler.allProcessors.forEach { processor in
            configuration.userContentController.addScriptMessageHandler(handler, contentWorld: world, name: processor.handlerName)
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

extension JsContextIdentifier {
    func withUrl(_ url: URL) -> Self {
        JsContextIdentifier(tab: tab, url: url)
    }
}
