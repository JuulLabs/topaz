import Observation
import Settings
import SwiftUI
import WebView

@MainActor
@Observable
public final class SearchBarModel {

    private struct LookupError: Error {}

    private let hostnameRegex = try? Regex("^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]).)*([A-Za-z]|[A-Za-z][A-Za-z0-9-]*[A-Za-z0-9])$")

    private enum HostnameLookup {
        case none
        case success(URL)
        case timeout
    }

    enum FocusedField {
        case searchBar
    }

    enum InfoIconMode: Identifiable {
        case showSecure(URL), showInsecure(URL)

        var id: Bool {
            switch self {
            case .showSecure: true
            case .showInsecure: false
            }
        }

        var url: URL {
            switch self {
            case let .showSecure(url): url
            case let .showInsecure(url): url
            }
        }
    }

    enum StopOrReloadMode {
        case showStopLoading, showReload
    }

    let navigator: WebNavigator

    var focusedField: FocusedField?
    var presentingInfoSheet: InfoIconMode?
    var searchString: String = ""
    var onSubmit: (URL) -> Void = { _ in }

    init(navigator: WebNavigator = WebNavigator()) {
        self.navigator = navigator
    }

    func didSubmitSearchString() {
        Task {
            guard let sanitized = sanitizeInput(query: searchString) else { return }
            self.focusedField = nil

            // If the user typed a full URL
            if let derivedUrl = URL(string: sanitized), derivedUrl.isHttp {
                onSubmit(derivedUrl)
                return
            }

            switch await buildHostNameUrl(hostname: sanitized) {
            case .none:
                // Treat what they typed as a search query
                if let derivedUrl = searchUrl(query: sanitized) {
                    onSubmit(derivedUrl)
                }
            case let .success(url):
                // The user typed something that resolves to a host. i.e. www.google.com or amazon.co.uk
                onSubmit(url)
            case .timeout:
                // Some sort of network error happened during DNS lookup and the operation timed out
                return
            }
        }
    }

    var infoIconMode: InfoIconMode? {
        guard case let .complete(url) = navigator.loadingState else {
            return nil
        }
        return switch url.scheme?.lowercased() {
        case "http": .showInsecure(url)
        case "https": .showSecure(url)
        default: nil
        }
    }

    var stopOrReloadMode: StopOrReloadMode? {
        switch navigator.loadingState {
        case .inProgress: .showStopLoading
        case .complete: .showReload
        default: nil
        }
    }

    func stopButtonTapped() {
        navigator.stopLoading()
    }

    func reloadButtonTapped() {
        guard case let .complete(url) = navigator.loadingState, !url.isAboutBlank() else {
            // We did not manage to load anything - re-submit the original query
            didSubmitSearchString()
            return
        }
        navigator.reload()
    }

    func infoButtonTapped() {
        presentingInfoSheet = infoIconMode
    }

    private func searchUrl(query: String) -> URL? {
        loadPreferredSearchEngine().searchUrl(for: query)
    }

    // TODO: apply valid-character-only filter to input as it is typed instead
    private func sanitizeInput(query: String) -> String? {
        let stripped = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.count > 0 ? stripped : nil
    }

    private func buildHostNameUrl(hostname: String) async -> HostnameLookup {
        guard (try? hostnameRegex?.wholeMatch(in: hostname)) != nil else {
            return .none
        }

        let result = await hostnameResolves(hostname, within: 10).map { domainFound in
            if domainFound, let url = URL(string: "https://" + hostname) {
                HostnameLookup.success(url)
            } else {
               HostnameLookup.none
            }
        }

        switch result {
        case .success(let lookup):
            return lookup
        case .failure:
            return .timeout
        }
    }

    private func hostnameResolves(_ hostname: String, within seconds: Int) async -> Result<Bool, any Error> {
        let resolveTask = Task.detached {
            let taskResult = gethostbyname(hostname) != nil
            try Task.checkCancellation()
            return taskResult
        }

        let timeoutTask = Task {
            try await Task.sleep(for: .seconds(seconds))
            resolveTask.cancel()
        }

        do {
            let result = try await resolveTask.value
            timeoutTask.cancel()
            return .success(result)
        } catch {
            return .failure(LookupError())
        }
    }
}

extension URL {
    var isHttp: Bool {
        scheme?.lowercased().hasPrefix("http") == true
    }
}
