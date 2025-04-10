import Foundation

public struct WebOrigin: Sendable, Equatable, Codable {
    public let domain: String
    public let scheme: String
    public let port: Int

    public var urlStringRepresentation: String {
        "\(scheme)://\(domain):\(port)"
    }

    public init(domain: String, scheme: String, port: Int) {
        self.domain = domain
        self.scheme = scheme
        self.port = port
    }
}
