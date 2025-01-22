import Observation
import Settings
import SwiftUI

@MainActor
@Observable
public final class SearchBarModel {
    enum FocusedField {
        case searchBar
    }

    var focusedField: FocusedField?
    var searchString: String = ""
    var onSubmit: (URL) -> Void = { _ in }

    func didSubmitSearchString() {
        guard let sanitized = sanitizeInput(query: searchString) else { return }
        self.focusedField = nil
        if let derivedUrl = URL(string: sanitized), derivedUrl.isHttp {
            onSubmit(derivedUrl)
        } else if let derivedUrl = searchUrl(query: sanitized) {
            onSubmit(derivedUrl)
        }
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
