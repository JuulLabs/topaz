import Foundation

public protocol SearchEngineProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    func searchUrl(for searchTerm: String) -> URL?
}

public let defaultSearchEngines: [SearchEngineProvider] = [
    DuckDuckGo(),
    Google(),
    Bing(),
]

public let defaultSearchEngine: SearchEngineProvider = DuckDuckGo()

public func loadPreferredSearchEngine(from storage: SettingsStorage = .shared) -> SearchEngineProvider {
    let engineId: String? = storage.object(forKey: .preferredSearchEngineIdKey)
    return defaultSearchEngines.first(where: { $0.id == engineId }) ?? defaultSearchEngine
}
