import AppMessage
import WebView

/// Bridges `AppMessage`'s page-agnostic `AppMessageHost` contract to a concrete `WebPageModel`.
///
/// Lives in `App` because it's the only module that sees both `AppMessage` and `WebView`. Holds the
/// page weakly so the per-page processor can't keep a torn-down page alive; a stale page resolves
/// host operations as failures.
@MainActor
struct WebPageAppMessageHost: AppMessageHost {
    weak var page: WebPageModel?

    func setUserAgentMode(_ mode: String) async -> Bool {
        page?.setUserAgentMode(mode) ?? false
    }
}
