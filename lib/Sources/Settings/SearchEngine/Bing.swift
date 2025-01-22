import Foundation

struct Bing: SearchEngineProvider {
    private static let hostname: String = "www.bing.com"

    let id: String = hostname
    let displayName: String = "bing.com"

    func searchUrl(for searchTerm: String) -> URL? {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: searchTerm),
        ]
        return URL(string: "https://\(Self.hostname)/search")?.appending(queryItems: queryItems)
    }
}
