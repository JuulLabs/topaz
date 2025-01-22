import Foundation

struct DuckDuckGo: SearchEngineProvider {
    private static let hostname: String = "duckduckgo.com"

    let id: String = hostname
    let displayName: String = hostname

    func searchUrl(for searchTerm: String) -> URL? {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: searchTerm),
        ]
        return URL(string: "https://\(Self.hostname)/")?.appending(queryItems: queryItems)
    }
}
