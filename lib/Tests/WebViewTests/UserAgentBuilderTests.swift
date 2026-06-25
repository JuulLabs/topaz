import Foundation
import Testing
@testable import WebView

@Suite("UserAgentBuilder")
struct UserAgentBuilderTests {
    /// A realistic, well-formed base UA string used across the happy-path cases.
    static let base = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    @Test
    func topazUserAgent_withKnownInputs_assemblesExpectedString() {
        let builder = UserAgentBuilder(base: Self.base, osVersionMajor: 26, osVersionMinor: 0, appVersion: "3.9.0")
        #expect(builder.topazUserAgent == "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Version/26.0 Topaz/3.9.0")
    }

    @Test
    func safariUserAgent_withKnownInputs_assemblesExpectedString() {
        let builder = UserAgentBuilder(base: Self.base, osVersionMajor: 26, osVersionMinor: 0, appVersion: "3.9.0")
        #expect(builder.safariUserAgent == "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Version/26.0 Safari/605.1.15")
    }

    @Test
    func safariUserAgent_parsesWebKitVersionFromBase() {
        let base = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/612.3.4 (KHTML, like Gecko) Mobile/15E148"
        let builder = UserAgentBuilder(base: base, osVersionMajor: 26, osVersionMinor: 0, appVersion: "3.9.0")
        #expect(builder.safariUserAgent == "\(base) Version/26.0 Safari/612.3.4")
    }

    @Test(arguments: [
        (26, 0, "26.0"),
        (26, 1, "26.1"),
        (18, 5, "18.5"),
    ])
    func versionToken_formatsOSVersionAsMajorMinor(major: Int, minor: Int, expected: String) {
        let topaz = UserAgentBuilder(base: Self.base, osVersionMajor: major, osVersionMinor: minor, appVersion: "3.9.0").topazUserAgent
        let safari = UserAgentBuilder(base: Self.base, osVersionMajor: major, osVersionMinor: minor, appVersion: "3.9.0").safariUserAgent
        #expect(topaz.contains("Version/\(expected) "))
        #expect(safari.contains("Version/\(expected) "))
    }

    @Test(arguments: [nil, "", "not a user agent", "AppleWebKit/605.1.15 but no mozilla token"])
    func base_whenNilOrGarbage_usesFallbackBaseConstant(garbage: String?) {
        let builder = UserAgentBuilder(base: garbage, osVersionMajor: 26, osVersionMinor: 0, appVersion: "3.9.0")
        #expect(builder.topazUserAgent == "\(UserAgentBuilder.fallbackBase) Version/26.0 Topaz/3.9.0")
        #expect(builder.safariUserAgent == "\(UserAgentBuilder.fallbackBase) Version/26.0 Safari/605.1.15")
    }

    @Test
    func webKitVersion_whenAppleWebKitTokenUnparseable_usesFallback() {
        let base = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/nonsense (KHTML, like Gecko) Mobile/15E148"
        let builder = UserAgentBuilder(base: base, osVersionMajor: 26, osVersionMinor: 0, appVersion: "3.9.0")
        // The (valid) base is preserved, only the WebKit token falls back.
        #expect(builder.safariUserAgent == "\(base) Version/26.0 Safari/\(UserAgentBuilder.fallbackWebKitVersion)")
        #expect(UserAgentBuilder.fallbackWebKitVersion == "605.1.15")
    }

    @Test
    func appVersion_whenNil_usesFallbackAppVersionConstant() {
        let builder = UserAgentBuilder(base: Self.base, osVersionMajor: 26, osVersionMinor: 0, appVersion: nil)
        #expect(builder.topazUserAgent == "\(Self.base) Version/26.0 Topaz/\(UserAgentBuilder.fallbackAppVersion)")
    }

    @Test
    func bothModes_shareIdenticalVersionToken() {
        let builder = UserAgentBuilder(base: Self.base, osVersionMajor: 26, osVersionMinor: 1, appVersion: "3.9.0")
        let topazToken = builder.topazUserAgent.components(separatedBy: " ").first { $0.hasPrefix("Version/") }
        let safariToken = builder.safariUserAgent.components(separatedBy: " ").first { $0.hasPrefix("Version/") }
        #expect(topazToken == "Version/26.1")
        #expect(safariToken == "Version/26.1")
        #expect(topazToken == safariToken)
    }
}
