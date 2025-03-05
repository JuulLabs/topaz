import WebKit

@MainActor
func cleanWebCache() {
    HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
    print("[WebCacheCleaner] All cookies deleted")

    WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
        records.forEach { record in
            WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            print("[WebCacheCleaner] Record \(record) deleted")
        }
    }
}
