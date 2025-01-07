import Foundation

public struct FileDataStorage: DataStorage {

    public init() {
    }

    public func load(for key: String) async throws -> Data {
        return try Data(contentsOf: url(for: key))
    }

    public func save(_ data: Data, for key: String) async throws {
        try data.write(to: url(for: key), options: .atomic)
    }

    private func url(for key: String) -> URL {
        URL.documentsDirectory.appendingPathComponent(key).appendingPathExtension("json")
    }
}
