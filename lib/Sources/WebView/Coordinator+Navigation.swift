import Foundation
import WebKit

extension Coordinator: WKNavigationDelegate {

    // Request has been sent to the web server and we are ready to start receiving a response
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = navigatingToUrl {
            didBeginNavigation(to: url, in: webView)
        }
    }

    // Started receiving a response and will attempt to begin parsing the HTML
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        didCommitNavigation(in: webView)
    }

    // All data received and if DOM is not already complete it will be very soon
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = navigatingToUrl {
            didFinishNavigation(to: url, in: webView)
        }
        navigatingToUrl = nil
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let url = navigationAction.request.url {
            navigatingToUrl = url
        } else {
            navigatingToUrl = nil
        }
        return .allow
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        return .allow
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        navigatingToUrl = nil
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        navigatingToUrl = nil
    }
}
