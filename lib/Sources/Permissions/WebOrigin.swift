import Foundation

public struct WebOrigin: Sendable, Equatable, Codable {
    public let domain: String
    public let scheme: String
    public let port: Int? // Optional because scheme implies a default

    public var urlStringRepresentation: String {
        if let port {
            "\(scheme)://\(domain):\(port)"
        } else {
            "\(scheme)://\(domain)"
        }
    }

    public init?(url: URL) {
        guard let domain = url.host(percentEncoded: false) else { return nil }
        guard let scheme = url.scheme else { return nil }
        self.domain = domain
        self.scheme = scheme
        self.port = url.port
    }
}
