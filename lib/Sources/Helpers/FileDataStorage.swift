import Foundation

public struct FileDataStorage: DataStorage {
    private let directory: URL
    private let pathExtension: String

    public init(directory: URL = .documentsDirectory, pathExtension: String = "json") {
        self.directory = directory
        self.pathExtension = pathExtension
    }

    public func load(for key: String) async throws -> Data {
        return try Data(contentsOf: url(for: key))
    }

    public func save(_ data: Data, for key: String) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url(for: key), options: .atomic)
    }

    public func remove(for key: String) async throws {
        let url = url(for: key)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        try FileManager.default.removeItem(at: url)
    }

    public func removeAll() async throws {
        let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for url in contents ?? [] where url.pathExtension == pathExtension {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func url(for key: String) -> URL {
        directory.appendingPathComponent(key).appendingPathExtension(pathExtension)
    }
}
