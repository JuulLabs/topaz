import Observation
import Settings
import SwiftUI
import WebView

@MainActor
@Observable
public final class SearchBarModel {
    enum FocusedField {
        case searchBar
    }

    enum StopOrReloadMode {
        case showStopLoading, showReload
    }

    let navigator: WebNavigator

    var focusedField: FocusedField?
    var searchString: String = ""
    var onSubmit: (URL) -> Void = { _ in }

    init(navigator: WebNavigator = WebNavigator()) {
        self.navigator = navigator
    }

    func didSubmitSearchString() {
        guard let sanitized = sanitizeInput(query: searchString) else { return }
        self.focusedField = nil
        if let derivedUrl = URL(string: sanitized), derivedUrl.isHttp {
            onSubmit(derivedUrl)
        } else if let derivedUrl = searchUrl(query: sanitized) {
            onSubmit(derivedUrl)
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
        navigator.reload()
    }

    private func searchUrl(query: String) -> URL? {
        loadPreferredSearchEngine().searchUrl(for: query)
    }

    // TODO: appply valid-character-only filter to input as it is typed instead
    private func sanitizeInput(query: String) -> String? {
        let stripped = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.count > 0 ? stripped : nil
    }
}

extension URL {
    var isHttp: Bool {
        scheme?.lowercased().hasPrefix("http") == true
    }
}
