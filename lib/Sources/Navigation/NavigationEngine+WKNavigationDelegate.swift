import Foundation
import OSLog
import WebKit

private let log = Logger(subsystem: "WebView", category: "NavigationDelegate")

extension NavigationEngine: WKNavigationDelegate {

    // MARK: - Policy decisions

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            log.warning("Request ignored due to nil URL action=\(navigationAction)")
            return .cancel
        }
        guard let newRequest = NavigationRequest(action: navigationAction) else {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    log.warning("System URL open denied for \(url.absoluteString)")
                }
            }
            log.debug("Request delegated to system action=\(navigationAction)")
            return .cancel
        }
        latestRequest = newRequest
        log.debug("Request allowed action=\(navigationAction)")
        return .allow
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        rejectionReason = nil
        rejectionStatusCode = nil
        guard let latestRequest else {
            rejectionReason = "Out-of-band navigation response"
            log.warning("Unexpected response ignored response=\(navigationResponse)")
            return .cancel
        }
        guard navigationResponse.canShowMIMEType else {
            rejectionReason = "Unsupported mime-type \(navigationResponse.response.mimeType ?? "nil")"
            log.warning("Response ignored due to unsupported mime-type response=\(navigationResponse)")
            return .cancel
        }
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                rejectionStatusCode = httpResponse.statusCode
                log.warning("Response rejected statusCode=\(httpResponse.statusCode) url=\(latestRequest.url.absoluteString)")
                return .cancel
            }
            log.info("Response accepted statusCode=\(httpResponse.statusCode) url=\(latestRequest.url.absoluteString)")
        } else {
            log.info("Response accepted url=\(latestRequest.url.absoluteString)")
        }
        return .allow
    }

    // MARK: - Navigation logic

    // Request has been sent to the web server and we are ready to start receiving a response
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let request = latestRequest {
            log.debug("Provisional navigation started navigation=\(navigation)")
            let navigationItem = NavigationItem(navigation: navigation, request: request)
            navigations[navigation] = navigationItem
            navigator.startObservingLoadingProgress(of: webView)
            delegate?.didInitiateNavigation(navigationItem, in: webView)
        } else {
            log.warning("Unexpected provisional navigation ignored navigation=\(navigation)")
        }
    }

    // Started receiving a response and will attempt to begin parsing the HTML
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let navigationItem = navigations[navigation] else {
            // Ignore untracked navigation - it is probably a request that was rejected in the decidePolicyFor method
            log.debug("Untracked navigation commit ignored navigation=\(navigation)")
            return
        }
        log.debug("Committed to load navigation=\(navigation)")
        latestRequest = nil
        delegate?.didBeginLoading(navigationItem, in: webView)
    }

    // All data received and if DOM is not already complete it will be very soon
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let navigationItem = navigations.removeValue(forKey: navigation) else {
            // Ignore untracked navigation - it is probably a request that was rejected in the decidePolicyFor method
            log.debug("Untracked navigation finalization ignored navigation=\(navigation)")
            return
        }
        log.debug("Finished loading navigation=\(navigation)")
        delegate?.didEndLoading(navigationItem, in: webView)
    }

    // MARK: - Error handling

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        log.debug("Provisional navigation failed navigation=\(navigation) error=\(error)")
        latestRequest = nil
        handleError(error, for: navigation, in: webView)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        log.debug("Navigation failed navigation=\(navigation) error=\(error)")
        latestRequest = nil
        handleError(error, for: navigation, in: webView)
    }
}
