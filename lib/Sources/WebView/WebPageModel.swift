import Foundation
import JsMessage
import Observation
import SwiftUI
import WebKit

@MainActor
@Observable
public class WebPageModel {
    @ObservationIgnored
    private var kvoStore: [NSKeyValueObservation] = []

    public let config: WKWebViewConfiguration
    public let contextId: JsContextIdentifier
    public let tab: Int
    public private(set) var url: URL

    public var loadingState: WebPageLoadingState = .initializing

    /// This remains true until we are somewhat confident that content can render
    /// Showing the WKWebView earlier than this will just display a black void
    public var isPerformingInitialContentLoad: Bool = true

    public let navigator: WebNavigator

    let messageProcessorFactory: JsMessageProcessorFactory

    // TODO: dynamically construct this
    let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Version/3.9.0 Topaz/3.9.0"

    public var hostname: String {
        url.host(percentEncoded: false) ?? "unknown"
    }

    public var onPageLoaded: (URL) -> Void = { _ in }

    public init(
        tab: Int,
        url: URL,
        config: WKWebViewConfiguration,
        messageProcessorFactory: JsMessageProcessorFactory
    ) {
        self.contextId = JsContextIdentifier(tab: tab, url: url)
        self.tab = tab
        self.url = url
        self.config = config
        self.messageProcessorFactory = messageProcessorFactory
        self.navigator = WebNavigator()
    }

    public func loadNewPage(url: URL) {
        self.url = url
    }

    func didInitializeWebView(_ webView: WKWebView) {
        monitorLoadingProgress(of: webView)
    }

    func deinitialize(webView: WKWebView) {
        kvoStore.forEach { $0.invalidate() }
        kvoStore.removeAll()
    }

    func didCommitNavigation() {
        // Invoked when we start to receive a response from the web server
        withAnimation(.easeInOut(duration: 0.25)) {
            isPerformingInitialContentLoad = false
        }
    }

    private func monitorLoadingProgress(of webView: WKWebView) {
        let loading = webView.observe(\.isLoading, options: .new) { [weak self] webView, change in
            guard let isLoading = change.newValue else { return }
            Task { @MainActor in
                guard let self else { return }
                if isLoading {
                    // We are usually already in progress by the time isLoading flips to true
                    guard case .inProgress = self.loadingState else {
                        self.loadingState = .inProgress(0.0)
                        return
                    }
                } else {
                    if self.loadingState.isProgressIncomplete {
                        // Smooth out the transition to 100% with a small delay
                        self.loadingState = .inProgress(1.0)
                        try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 15)
                        // Double check state didn't change while we slept
                        if self.loadingState.isProgressComplete {
                            self.loadingState = .complete
                            if let url = webView.url {
                                self.onPageLoaded(url)
                            }
                        }
                    } else {
                        self.loadingState = .complete
                        if let url = webView.url {
                            self.onPageLoaded(url)
                        }
                    }
                }
            }
        }
        kvoStore.append(loading)

        let progress = webView.observe(\.estimatedProgress, options: .new) { [weak self] _, change in
            guard let progress = change.newValue, progress < 1.0 else { return }
            Task { @MainActor in
                self?.loadingState = .inProgress(Float(progress))
            }
        }
        kvoStore.append(progress)
    }
}
