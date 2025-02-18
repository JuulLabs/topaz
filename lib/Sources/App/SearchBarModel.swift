import Observation
import Settings
import SwiftUI
import WebView

@MainActor
@Observable
public final class SearchBarModel {

    private let hostnameRegex = try? Regex("^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]).)*([A-Za-z]|[A-Za-z][A-Za-z0-9-]*[A-Za-z0-9])$")

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
                // If the user typed something that resolves to a host. i.e. www.google.com or amazon.co.uk
            } else if let url = await hostNameUrl(hostname: sanitized) {
                onSubmit(url)
                // Treat what they typed as a search query
            } else if let derivedUrl = searchUrl(query: sanitized) {
                onSubmit(derivedUrl)
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

    // TODO: appply valid-character-only filter to input as it is typed instead
    private func sanitizeInput(query: String) -> String? {
        let stripped = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.count > 0 ? stripped : nil
    }

    private func hostNameUrl(hostname: String) async -> URL? {
        guard (try? hostnameRegex?.wholeMatch(in: hostname)) != nil else {
            return nil
        }
        guard await hostnameResolves(hostname, within: 5) else {
            return nil
        }
        return URL(string: "https://" + hostname)
    }

    private func hostnameResolves(_ hostname: String, within seconds: Int) async -> Bool {
        let resolveTask = Task {
            let taskResult = await hostnameResolves(hostname)
            try Task.checkCancellation()
            return taskResult
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(seconds) * NSEC_PER_SEC)
            resolveTask.cancel()
        }

        do {
            let result = try await resolveTask.value
            timeoutTask.cancel()
            return result
        } catch {
            return false
        }
    }

    private func hostnameResolves(_ hostname: String) async -> Bool {
        await Task { return gethostbyname(hostname) != nil }.value
    }
}

extension URL {
    var isHttp: Bool {
        scheme?.lowercased().hasPrefix("http") == true
    }
}
