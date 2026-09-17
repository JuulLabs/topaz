import Foundation

public actor InMemoryDataStorage: DataStorage {
    public struct KeyNotFound: Error {}

    private var data: [String: Data]

    public init(data: [String: Data] = [:]) {
        self.data = data
    }

    public var keys: Set<String> {
        Set(data.keys)
    }

    public func load(for key: String) async throws -> Data {
        guard let value = data[key] else {
            throw KeyNotFound()
        }
        return value
    }

    public func save(_ data: Data, for key: String) async throws {
        self.data[key] = data
    }

    public func remove(for key: String) async throws {
        data.removeValue(forKey: key)
    }

    public func removeAll() async throws {
        data.removeAll()
    }
}
