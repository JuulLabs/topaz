import Foundation
import WebKit

@MainActor
class NavigationStateObserver {
    private var kvoStore: [NSKeyValueObservation] = []

    var onNavigationStateChange: (WKWebView) -> Void = { _ in }

    init(webView: WKWebView) {
        observe(webView)
    }

    private func observe(_ webView: WKWebView) {
        let backObservation = webView.observe(\.canGoBack, options: .new) { [weak self] webView, _ in
            Task { @MainActor in
                self?.onNavigationStateChange(webView)
                print("canGoBack changed")
            }
        }
        kvoStore.append(backObservation)

        let forwardObservation = webView.observe(\.canGoForward, options: .new) { [weak self] webView, _ in
            Task { @MainActor in
                self?.onNavigationStateChange(webView)
                print("canGoForward changed")
            }
        }
        kvoStore.append(forwardObservation)
    }
}
