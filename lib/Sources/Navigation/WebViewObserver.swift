import Foundation
import Observation
import WebKit

@MainActor
@Observable
public class WebViewObserver {
    @ObservationIgnored
    private var kvoStore: [NSKeyValueObservation] = []

    private var isLoading: Bool = false
    private var progress: Float = 0.0
    private var url: URL?

    public var status: WebPageLoadingState {
        getLoadingState()
    }

    init(webView: WKWebView) {
        monitorLoadingProgress(of: webView)
    }

    private func getLoadingState() -> WebPageLoadingState {
        guard let url else {
            return isLoading ? .inProgress(progress) : .initializing
        }
        return isLoading ? .inProgress(progress) : .complete(url)
    }

    private func monitorLoadingProgress(of webView: WKWebView) {
        let loadingObservation = webView.observe(\.isLoading, options: .new) { [weak self] _, change in
            guard let isLoading = change.newValue else { return }
            Task { @MainActor in
                guard let self else { return }
                if self.isLoading && !isLoading && self.progress < 1.0 {
                    self.progress = 1.0
                }
                self.isLoading = isLoading
            }
        }
        kvoStore.append(loadingObservation)

        let progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] _, change in
            guard let progress = change.newValue, progress >= 0.0, progress <= 1.0 else { return }
            Task { @MainActor in
                self?.progress = Float(progress)
            }
        }
        kvoStore.append(progressObservation)

        let urlObservation = webView.observe(\.url, options: .new) { [weak self] _, change in
            guard let url = change.newValue else { return }
            Task { @MainActor in
                self?.url = url
            }
        }
        kvoStore.append(urlObservation)
    }
}
