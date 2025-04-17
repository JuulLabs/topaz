import Foundation
import JsMessage
import Navigation
import Observation
import Permissions
import SwiftUI
import WebKit

@MainActor
@Observable
public class WebPageModel: Identifiable {
    private var permissionsRequest: CheckedContinuation<Bool, Never>?

    public let config: WKWebViewConfiguration
    public let contextId: JsContextIdentifier
    public let tab: Int
    public private(set) var url: URL
    public private(set) var webOrigin: WebOrigin?

    /// This remains true until we are somewhat confident that content can render
    /// Showing the WKWebView earlier than this will just display a black void
    public var isPerformingInitialContentLoad: Bool = true

    public let navigator: WebNavigator

    public var launchNewPage: ((URL) -> Void)?

    public var presentPermissionsDialog: Bool = false

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

    func didBeginLoading(url: URL) {
        // Invoked when we start to receive a response from the web server
        webOrigin = WebOrigin(url: url)
        withAnimation(.easeInOut(duration: 0.25)) {
            isPerformingInitialContentLoad = false
        }
    }

    func requestAuthorization() async -> Bool {
        guard let webOrigin else {
            return false
        }
        guard PermissionsModel.shared.isAuthorized(origin: webOrigin) else {
            return await requestUserPermission(for: webOrigin)
        }
        return true
    }

    var permissionsDialogMessage: String {
        "\(webOrigin?.domain ?? "This website") would like to find and connect to Bluetooth devices."
    }

    func denyPermissionsButtonTapped() {
        // TODO: give the user the option to remember the decision and cache the result for some period of time
        // so that we stop prompting them on every attempted bluetooth operation
        closePermissionsRequest(allowed: false)
    }

    func allowPermissionsButtonTapped() {
        closePermissionsRequest(allowed: true)
    }

    private func requestUserPermission(for origin: WebOrigin) async -> Bool {
        let userDidAllow = await withCheckedContinuation { continuation in
            permissionsRequest = continuation
            presentPermissionsDialog = true
        }
        if userDidAllow {
            PermissionsModel.shared.authorize(origin: origin)
        }
        return userDidAllow
    }

    private func closePermissionsRequest(allowed: Bool) {
        permissionsRequest?.resume(returning: allowed)
        permissionsRequest = nil
    }
}
