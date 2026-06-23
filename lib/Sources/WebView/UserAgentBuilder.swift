import Foundation

/// Builds the user-agent strings used by the web view in both Topaz and Safari modes.
///
/// This is a pure value type: it takes every input it needs as a parameter — the base UA
/// string, the OS version, and the app version — and performs no `WKWebView`, `Bundle`, or
/// `ProcessInfo` access. That makes it fully unit-testable in isolation and free of any
/// `@MainActor` binding.
///
/// The final string shapes are:
///
/// | Mode   | Result                                                |
/// |--------|-------------------------------------------------------|
/// | Topaz  | `<base> Version/<major>.<minor> Topaz/<appVersion>`   |
/// | Safari | `<base> Version/<major>.<minor> Safari/<webkit>`      |
///
/// The `Version/<major>.<minor>` token is shared by both modes. Fallbacks are applied
/// internally when an input is `nil` or unparseable, so a malformed UA is never emitted.
struct UserAgentBuilder {
    /// Well-formed iOS 18.x base used when the supplied base string is missing or unusable.
    static let fallbackBase = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    /// WebKit version used when one cannot be parsed from the base string.
    static let fallbackWebKitVersion = "605.1.15"

    /// App version used when no app version is supplied.
    static let fallbackAppVersion = "3.9.0"

    private let base: String
    private let osVersionMajor: Int
    private let osVersionMinor: Int
    private let appVersion: String

    init(base: String?, osVersionMajor: Int, osVersionMinor: Int, appVersion: String?) {
        self.base = Self.sanitized(base: base)
        self.osVersionMajor = osVersionMajor
        self.osVersionMinor = osVersionMinor
        self.appVersion = appVersion ?? Self.fallbackAppVersion
    }

    /// `<base> Version/<major>.<minor> Topaz/<appVersion>`
    var topazUserAgent: String {
        "\(base) \(versionToken) Topaz/\(appVersion)"
    }

    /// `<base> Version/<major>.<minor> Safari/<webkit>`
    var safariUserAgent: String {
        "\(base) \(versionToken) Safari/\(webKitVersion)"
    }

    /// The `Version/<major>.<minor>` token shared by both modes.
    private var versionToken: String {
        "Version/\(osVersionMajor).\(osVersionMinor)"
    }

    /// The WebKit version parsed from the base string, or the fallback when it cannot be parsed.
    private var webKitVersion: String {
        Self.parseWebKitVersion(from: base) ?? Self.fallbackWebKitVersion
    }

    /// Returns the supplied base if it looks like a usable user-agent string, otherwise the
    /// hardcoded fallback. A base is considered usable only when it carries the `Mozilla/` and
    /// `AppleWebKit/` markers; anything else is treated as garbage.
    private static func sanitized(base: String?) -> String {
        guard let base, base.contains("Mozilla/"), base.contains("AppleWebKit/") else {
            return fallbackBase
        }
        return base
    }

    /// Extracts the version following the `AppleWebKit/` token of the base string. Returns `nil`
    /// when no `AppleWebKit/<digits>` token is present so the caller can apply a fallback.
    private static func parseWebKitVersion(from base: String) -> String? {
        let prefix = "AppleWebKit/"
        guard let range = base.range(
            of: prefix + "[0-9]+(\\.[0-9]+)*",
            options: .regularExpression
        ) else {
            return nil
        }
        return String(base[range].dropFirst(prefix.count))
    }
}
