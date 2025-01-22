import Foundation

struct Google: SearchEngineProvider {
    private static let hostname: String = "google.com"

    let id: String = hostname
    let displayName: String = hostname

    func searchUrl(for searchTerm: String) -> URL? {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: searchTerm),
        ]
        return URL(string: "https://\(Self.hostname)/search")?.appending(queryItems: queryItems)
    }
}
