@testable import Permissions
import Foundation
import Testing

struct PermissionsModelTests {

    static let unique: [WebOrigin] = [
        .init(url: URL(string: "https://unique.com")!)!,
    ]

    static let sameSchemeOptionalPort: [WebOrigin] = [
        // These two differ only by port where one has the implicit default port
        .init(url: URL(string: "https://same-scheme-optional-port.com")!)!,
        .init(url: URL(string: "https://same-scheme-optional-port.com:8443")!)!,
    ]

    static let sameSchemeExplicitPort: [WebOrigin] = [
        // These two differ only by port where both have explicit ports specified
        .init(url: URL(string: "https://same-scheme-explicit-port.com:443")!)!,
        .init(url: URL(string: "https://same-scheme-explicit-port.com:8443")!)!,
    ]

    static let samePort: [WebOrigin] = [
        // These two differ only by scheme
        .init(url: URL(string: "https://same-port.com")!)!,
        .init(url: URL(string: "http://same-port.com")!)!,
    ]

    static let duplicate: [WebOrigin] = [
        // These three overlap by both scheme and port
        .init(url: URL(string: "https://duplicate.com")!)!,
        .init(url: URL(string: "https://duplicate.com:8443")!)!,
        .init(url: URL(string: "http://duplicate.com")!)!,
    ]

    var allOrigins: [WebOrigin] {
        Self.unique + Self.sameSchemeOptionalPort + Self.sameSchemeExplicitPort + Self.samePort + Self.duplicate
    }

    @Test(arguments: Self.unique)
    func displayString_uniqueDomain_showsDomainOnly(origin: WebOrigin) async {
        let result = displayString(for: origin, in: allOrigins)
        #expect(result == "unique.com")
    }

    @Test(arguments: Self.sameSchemeOptionalPort)
    func displayString_withDuplicateSchemesAndOptionalPort_showsPortWhenPresent(origin: WebOrigin) async throws {
        let result = displayString(for: origin, in: allOrigins)
        if let port = origin.port {
            #expect(result == "same-scheme-optional-port.com:\(port)")
        } else {
            #expect(result == "same-scheme-optional-port.com")
        }
    }

    @Test(arguments: Self.sameSchemeExplicitPort)
    func displayString_withDuplicateSchemesAndSpecifiedPorts_showsPortAlways(origin: WebOrigin) async throws {
        let result = displayString(for: origin, in: allOrigins)
        let port = try #require(origin.port)
        #expect(result == "same-scheme-explicit-port.com:\(port)")
    }

    @Test(arguments: Self.samePort)
    func displayString_withDuplicatePorts_showsSchemeAlways(origin: WebOrigin) async {
        let result = displayString(for: origin, in: allOrigins)
        #expect(result == "\(origin.scheme)://same-port.com")
    }

    @Test(arguments: Self.duplicate)
    func displayString_withDuplicateSchemesAndPorts_showsSchemeAlwaysAndPortWhenPresent(origin: WebOrigin) async throws {
        let result = displayString(for: origin, in: allOrigins)
        if let port = origin.port {
            #expect(result == "\(origin.scheme)://duplicate.com:\(port)")
        } else {
            #expect(result == "\(origin.scheme)://duplicate.com")
        }
    }
}
