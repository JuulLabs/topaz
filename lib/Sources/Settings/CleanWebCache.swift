import WebKit

/// Wipes all persisted web data. Returns only once the removal has completed so
/// callers can sequence dependent work (e.g. reloading pages) after the wipe.
@MainActor
func cleanWebCache() async {
    HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
    await WKWebsiteDataStore.default().removeData(
        ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
        modifiedSince: Date.distantPast
    )
}
