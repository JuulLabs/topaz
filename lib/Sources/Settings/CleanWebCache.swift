import WebKit

@MainActor
func cleanWebCache() {
    HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

    WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
        records.forEach { record in
            WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
        }
    }
}
