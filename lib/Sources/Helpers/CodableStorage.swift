import Foundation

public protocol CodableStorage: Sendable {
    func load<Value: Codable & Sendable>(for key: String) async throws -> Value
    func save<Value: Codable & Sendable>(_ value: Value, for key: String) async throws
}

public struct JsonDataStorage: CodableStorage {
    private let delegate: DataStorage

    public init(_ delegate: DataStorage = FileDataStorage()) {
        self.delegate = delegate
    }

    public func load<Value: Codable & Sendable>(for key: String) async throws -> Value {
        try await JSONDecoder().decode(Value.self, from: try delegate.load(for: key))
    }

    public func save<Value: Codable & Sendable>(_ value: Value, for key: String) async throws {
        try await delegate.save(try JSONEncoder().encode(value), for: key)
    }
}

public actor InMemoryStorage: CodableStorage {
    public struct KeyNotFound: Error {}

    private var data: [String: Data] = [:]

    public init(data: [String: Data] = [:]) {
        self.data = data
    }

    public func load<Value: Codable & Sendable>(for key: String) async throws -> Value {
        guard let value = data[key] else {
            throw KeyNotFound()
        }
        return try JSONDecoder().decode(Value.self, from: value)
    }

    public func save<Value: Codable & Sendable>(_ value: Value, for key: String) async throws {
        data[key] = try JSONEncoder().encode(value)
    }
}
