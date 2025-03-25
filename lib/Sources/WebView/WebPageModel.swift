import Foundation
import JsMessage
import Navigation
import Observation
import SwiftUI
import WebKit

@MainActor
@Observable
public class WebPageModel: Identifiable {
    public let config: WKWebViewConfiguration
    public let contextId: JsContextIdentifier
    public let tab: Int
    public private(set) var url: URL

    /// This remains true until we are somewhat confident that content can render
    /// Showing the WKWebView earlier than this will just display a black void
    public var isPerformingInitialContentLoad: Bool = true

    public let navigator: WebNavigator

    public var launchNewPage: ((URL) -> Void)?

    let messageProcessorFactory: JsMessageProcessorFactory

    // TODO: dynamically construct this
    let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Version/3.9.0 Topaz/3.9.0"

    public var hostname: String {
        url.host(percentEncoded: false) ?? "unknown"
    }

    public init(
        tab: Int,
        url: URL,
        config: WKWebViewConfiguration,
        messageProcessorFactory: JsMessageProcessorFactory,
        navigator: WebNavigator
    ) {
        self.contextId = JsContextIdentifier(tab: tab, url: url)
        self.tab = tab
        self.url = url
        self.config = config
        self.messageProcessorFactory = messageProcessorFactory
        self.navigator = navigator
    }

    public func loadNewPage(url: URL) {
        self.url = url
    }

    func createWebView() -> WKWebView {
         let webView = WKWebView(frame: .zero, configuration: config)
         webView.allowsBackForwardNavigationGestures = true
         return webView
    }

    func didBeginLoading() {
        // Invoked when we start to receive a response from the web server
        withAnimation(.easeInOut(duration: 0.25)) {
            isPerformingInitialContentLoad = false
        }
    }
}
