import Foundation

public protocol DataStorage: Sendable {
    func load(for key: String) async throws -> Data
    func save(_ data: Data, for key: String) async throws
}

public struct FileDataStorage: DataStorage {
    private let debounceInterval: Duration?
    private let debouncer: Debouncer

    public init(debounceInterval: Duration? = nil) {
        self.debounceInterval = debounceInterval
        self.debouncer = Debouncer()
    }

    public func load(for key: String) async throws -> Data {
        return try Data(contentsOf: url(for: key))
    }

    public func save(_ data: Data, for key: String) async throws {
        let url = url(for: key)
        if let debounceInterval {
            await debouncer.debounce(interval: debounceInterval) {
                try data.write(to: url, options: .atomic)
            }
        } else {
            try data.write(to: url, options: .atomic)
        }
    }

    private func url(for key: String) -> URL {
        URL.documentsDirectory.appendingPathComponent(key).appendingPathExtension("json")
    }
}
