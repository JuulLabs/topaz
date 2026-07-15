import Foundation
import JsMessage
import Navigation
import Observation
import Permissions
import SwiftUI
import VirtualKeyboard
import WebKit

// This is a workaround for an iOS issue that occurs with the view layout not being properly
// redrawn when keyboard focus on a WebView TextField that has a tool bar shifts to a
// native app TextField with no toolbar. This workaround removes the default toolbar that
// shows up for WebView TextFields. This isn't ideal--especially for websites that are expecting
// a toolbar for ease of UI use--but hopefully the issue will be fixed in an upcoming SwiftUI update.
private class NoKeyboardToolbarWebView: WKWebView {

    override var inputAccessoryView: UIView? {
        return nil // Hides the default accessory toolbar
    }
}

@MainActor
@Observable
public class WebPageModel: Identifiable {
    private var permissionsRequest: CheckedContinuation<Bool, Never>?
    private let scrollObserver: ScrollObserver

    /// Session-scoped machinery (navigation delegates, script handler lifecycle) owned by
    /// the model so the web view's lifetime is not bound to SwiftUI view mount/unmount.
    let sessionController = WebPageSessionController()

    /// The web view is owned (strongly) by the model and survives until `teardown()`.
    @ObservationIgnored
    private var ownedWebView: WKWebView?

    public let config: WKWebViewConfiguration
    public let contextId: JsContextIdentifier
    public let tab: Int
    public private(set) var url: URL
    public private(set) var webOrigin: WebOrigin?

    /// This remains true until we are somewhat confident that content can render
    /// Showing the WKWebView earlier than this will just display a black void
    public var isPerformingInitialContentLoad: Bool = true

    public let navigator: WebNavigator

    /// Invoked when the system kills this page's web content process. The page's Js
    /// heap (and polyfill object graph) is gone while native state survives; the owner
    /// is expected to tear this session down and rebuild it (converge-to-empty).
    @ObservationIgnored
    public var onWebContentProcessTerminated: (() -> Void)?

    public var presentPermissionsDialog: Bool = false

    public var isDownloadsPresented: Bool = false

    var messageProcessorFactory: JsMessageProcessorFactory

    enum UserAgentMode: String {
        case topaz
        case safari
    }

    private(set) var userAgentMode: UserAgentMode = .topaz

    /// The default WebKit user-agent for this process. It is constant for the process lifetime,
    /// so we read it once via KVC and cache it rather than instantiating a `WKWebView` repeatedly.
    private static let baseUserAgent: String? = WKWebView().value(forKey: "userAgent") as? String

    private var userAgentBuilder: UserAgentBuilder {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return UserAgentBuilder(
            base: Self.baseUserAgent,
            osVersionMajor: osVersion.majorVersion,
            osVersionMinor: osVersion.minorVersion,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        )
    }

    var customUserAgent: String {
        switch userAgentMode {
        case .topaz:
            userAgentBuilder.topazUserAgent
        case .safari:
            userAgentBuilder.safariUserAgent
        }
    }

    public var hostname: String {
        url.host(percentEncoded: false) ?? "unknown"
    }

    public init(
        tab: Int,
        url: URL,
        config: WKWebViewConfiguration,
        messageProcessorFactory: JsMessageProcessorFactory = .init(),
        navigator: WebNavigator,
        virtualKeyboardModel: VirtualKeyboardModel
    ) {
        self.contextId = JsContextIdentifier(tab: tab, url: url)
        self.tab = tab
        self.url = url
        self.config = config
        self.messageProcessorFactory = messageProcessorFactory
        self.navigator = navigator
        self.scrollObserver = .init(virtualKeyboardModel: virtualKeyboardModel)
    }

    public func loadNewPage(url: URL) {
        self.url = url
    }

    public func attach(messageProcessorFactory: JsMessageProcessorFactory) {
        self.messageProcessorFactory = messageProcessorFactory
    }

    public func setUserAgentMode(_ mode: String) -> Bool {
        guard let mode = UserAgentMode(rawValue: mode) else {
            return false
        }
        userAgentMode = mode
        ownedWebView?.customUserAgent = customUserAgent
        return true
    }

    /// Returns the model-owned web view, creating and initializing it on first access.
    func webView() -> WKWebView {
        if let ownedWebView {
            return ownedWebView
        }
        let webView = NoKeyboardToolbarWebView(frame: .zero, configuration: config)
#if DEBUG
        webView.isInspectable = true
#endif
        self.ownedWebView = webView
        webView.allowsBackForwardNavigationGestures = true
        scrollObserver.observe(webView: webView)
        sessionController.initialize(webView: webView, model: self)
        return webView
    }

    /// Explicitly tears down the web session: detaches the script handler (shutting down its
    /// message processors and any BLE connections they hold), clears delegates, and releases
    /// the web view. Idempotent. A subsequent `webView()` call starts a fresh session.
    public func teardown() {
        guard let webView = ownedWebView else { return }
        sessionController.deinitialize(webView: webView)
        ownedWebView = nil
    }

    func didBeginLoading(url: URL) {
        // Invoked when we start to receive a response from the web server
        webOrigin = WebOrigin(url: url)
        withAnimation(.easeInOut(duration: 0.25)) {
            isPerformingInitialContentLoad = false
        }
    }

    func didFinishLoading(url: URL) {
        self.url = url
    }

    func webContentProcessDidTerminate() {
        onWebContentProcessTerminated?()
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

    public var permissionsDialogMessage: String {
        "This will allow this website to find and connect to your Bluetooth® devices."
    }

    public func denyPermissionsButtonTapped() {
        // TODO: give the user the option to remember the decision and cache the result for some period of time
        // so that we stop prompting them on every attempted bluetooth operation
        closePermissionsRequest(allowed: false)
    }

    public func allowPermissionsButtonTapped() {
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
