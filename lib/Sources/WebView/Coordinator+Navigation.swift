import Foundation
import WebKit

extension Coordinator: WKNavigationDelegate {

    // Request has been sent to the web server and we are ready to start receiving a response
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webView.didStartProvisionalNavigation")
    }

    // Started receiving a response and will attempt to begin parsing the HTML
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webView.didCommitNavigation")
    }

    // All data received and if DOM is not already complete it will be very soon
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView.didFinishNavigation")
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let url = navigationAction.request.url {
            print("webView.decidePolicyFor: \(url.absoluteString)")
        }
        return .allow
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        print("webView.didFailProvisionalNavigation", error)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        print("webView.didFailNavigation", error)
    }
}
