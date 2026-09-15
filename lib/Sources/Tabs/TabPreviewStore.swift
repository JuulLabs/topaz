import Foundation
import Helpers
import OSLog

private let log = Logger(subsystem: "Topaz", category: "TabPreviewStore")

/// Persists one preview thumbnail per tab, keyed by the tab's stable identifier.
///
/// Thumbnails are regenerable, so they live in the caches directory: they are excluded
/// from backups and the system may purge them. Callers must therefore treat a missing
/// thumbnail as normal, not as an error.
public struct TabPreviewStore: Sendable {
    public static let fileExtension = "jpg"

    private let storage: DataStorage

    public init(storage: DataStorage) {
        self.storage = storage
    }

    public init() {
        self.init(
            storage: FileDataStorage(
                directory: URL.cachesDirectory.appending(path: "TabPreviews"),
                pathExtension: Self.fileExtension
            )
        )
    }

    public func load(for tabID: UUID) async -> Data? {
        try? await storage.load(for: tabID.uuidString)
    }

    public func save(_ data: Data, for tabID: UUID) async {
        do {
            try await storage.save(data, for: tabID.uuidString)
        } catch {
            log.error("Unable to save tab preview: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func remove(for tabID: UUID) async {
        try? await storage.remove(for: tabID.uuidString)
    }

    public func removeAll() async {
        try? await storage.removeAll()
    }
}
