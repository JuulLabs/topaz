import Foundation

public struct SettingsStorage: Sendable {
    public func object<T>(forKey key: String) -> T? {
        UserDefaults.standard.object(forKey: key) as? T
    }

    public func set<T>(value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

public extension SettingsStorage {
    static let shared = SettingsStorage()
}

public extension String {
    static let preferredSearchEngineIdKey = "PreferredSearchEngineId"
}
