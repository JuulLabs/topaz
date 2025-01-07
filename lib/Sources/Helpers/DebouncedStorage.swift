import Foundation

public struct DebouncedDataStorage: DataStorage {
    private let delegate: DataStorage
    private let debounceInterval: Duration
    private let debouncer: Debouncer

    public init(_ delegate: DataStorage, debounceInterval: Duration) {
        self.delegate = delegate
        self.debounceInterval = debounceInterval
        self.debouncer = Debouncer()
    }

    public func load(for key: String) async throws -> Data {
        return try await delegate.load(for: key)
    }

    public func save(_ data: Data, for key: String) async throws {
        await debouncer.debounce(interval: debounceInterval) {
            try await delegate.save(data, for: key)
        }
    }
}

public struct DebouncedCodableStorage: CodableStorage {
    private let delegate: CodableStorage
    private let debounceInterval: Duration
    private let debouncer: Debouncer

    public init(_ delegate: CodableStorage, debounceInterval: Duration) {
        self.delegate = delegate
        self.debounceInterval = debounceInterval
        self.debouncer = Debouncer()
    }

    public func load<Value: Codable & Sendable>(for key: String) async throws -> Value {
        try await delegate.load(for: key)
    }

    public func save<Value: Codable & Sendable>(_ value: Value, for key: String) async throws {
        await debouncer.debounce(interval: debounceInterval) {
            try await delegate.save(value, for: key)
        }
    }
}
