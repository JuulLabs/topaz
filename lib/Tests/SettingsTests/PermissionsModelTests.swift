@testable import Settings
import Foundation
import Testing

struct PermissionsModelTests {

    static let unique: [WebOrigin] = [
        .init(domain: "unique.com", scheme: "https", port: 443),
    ]

    static let sameScheme: [WebOrigin] = [
        // These two differ only by port
        .init(domain: "same-scheme.com", scheme: "https", port: 443),
        .init(domain: "same-scheme.com", scheme: "https", port: 8443),
    ]

    static let samePort: [WebOrigin] = [
        // These two differ only by scheme
        .init(domain: "same-port.com", scheme: "https", port: 80),
        .init(domain: "same-port.com", scheme: "http", port: 80),
    ]

    static let duplicate: [WebOrigin] = [
        // These three overlap by both scheme and port
        .init(domain: "duplicate.com", scheme: "https", port: 80),
        .init(domain: "duplicate.com", scheme: "https", port: 443),
        .init(domain: "duplicate.com", scheme: "http", port: 80),
    ]

    var allPermits: [WebOrigin] {
        Self.unique + Self.sameScheme + Self.samePort + Self.duplicate
    }

    @Test(arguments: Self.unique)
    func displayString_uniqueDomain_showsDomainOnly(permit: WebOrigin) async {
        let result = displayString(for: permit, in: allPermits)
        #expect(result == "unique.com")
    }

    @Test(arguments: Self.sameScheme)
    func displayString_withDuplicateSchemes_showsPort(permit: WebOrigin) async {
        let result = displayString(for: permit, in: allPermits)
        #expect(result == "same-scheme.com:\(permit.port)")
    }

    @Test(arguments: Self.samePort)
    func displayString_withDuplicatePorts_showsScheme(permit: WebOrigin) async {
        let result = displayString(for: permit, in: allPermits)
        #expect(result == "\(permit.scheme)://same-port.com")
    }

    @Test(arguments: Self.duplicate)
    func displayString_withDuplicateSchemesAndPorts_showsSchemeAndPort(permit: WebOrigin) async {
        let result = displayString(for: permit, in: allPermits)
        #expect(result == "\(permit.scheme)://duplicate.com:\(permit.port)")
    }
}
