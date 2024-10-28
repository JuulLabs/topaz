import Observation
import SwiftUI

@MainActor
@Observable
public class SearchBarModel {
    var searchString: String = ""
    var onSubmit: (URL) -> Void = { _ in }

    func didSubmitSearchString() {
        guard let sanitized = sanitizeInput(query: searchString) else { return }
        if let derivedUrl = URL(string: sanitized), derivedUrl.isHttp {
            onSubmit(derivedUrl)
        } else if let derivedUrl = duckduckUrl(query: sanitized) {
            onSubmit(derivedUrl)
        }
    }

    private func duckduckUrl(query: String) -> URL? {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
        ]
        return URL(string: "https://duckduckgo.com/")?.appending(queryItems: queryItems)
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
