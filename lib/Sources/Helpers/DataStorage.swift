import Foundation

public protocol DataStorage: Sendable {
    func load(for key: String) async throws -> Data
    func save(_ data: Data, for key: String) async throws
}
