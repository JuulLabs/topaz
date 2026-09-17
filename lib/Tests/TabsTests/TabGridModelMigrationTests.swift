import Foundation
import Helpers
@testable import Tabs
import Testing

@MainActor
struct TabGridModelMigrationTests {

    private func storage(_ values: [String: any Codable & Sendable]) async throws -> InMemoryStorage {
        let storage = InMemoryStorage()
        for (key, value) in values {
            try await storage.save(value, for: key)
        }
        return storage
    }

    @Test
    func performInitialLoad_withStoredTabs_restoresTheirIdentities() async throws {
        let stored = [
            StoredTab(url: URL(string: "https://one.example")!),
            StoredTab(url: URL(string: "https://two.example")!),
        ]
        let model = TabGridModel(store: try await storage(["savedTabs": stored]))
        await model.performInitialLoad()
        #expect(model.urls.map(\.absoluteString) == ["https://one.example", "https://two.example"])
        #expect(model.tabCells.map(\.tabID) == stored.map(\.id))
    }

    @Test
    func performInitialLoad_withOnlyLegacyUrls_mintsIdentitiesForThem() async throws {
        let urls = [URL(string: "https://one.example")!, URL(string: "https://two.example")!]
        let model = TabGridModel(store: try await storage(["savedTabURLs": urls]))
        await model.performInitialLoad()
        #expect(model.urls == urls)
        #expect(Set(model.tabCells.map(\.tabID)).count == 2)
    }

    @Test
    func performInitialLoad_withBothFormats_prefersTheCurrentOne() async throws {
        let stored = [StoredTab(url: URL(string: "https://current.example")!)]
        let legacy = [URL(string: "https://legacy.example")!]
        let model = TabGridModel(store: try await storage(["savedTabs": stored, "savedTabURLs": legacy]))
        await model.performInitialLoad()
        #expect(model.urls.map(\.absoluteString) == ["https://current.example"])
    }

    @Test
    func update_whenTheTabNavigates_keepsItsIdentityAndThumbnail() async throws {
        let stored = [StoredTab(url: URL(string: "https://one.example")!)]
        let model = TabGridModel(store: try await storage(["savedTabs": stored]))
        await model.performInitialLoad()
        model.update(url: URL(string: "https://one.example/next")!, at: 1)
        #expect(model.findTab(for: 1)?.tabID == stored[0].id)
    }

    @Test
    func previewDidUpdate_forAKnownTab_bumpsItsPreviewGeneration() async throws {
        let stored = [StoredTab(url: URL(string: "https://one.example")!)]
        let model = TabGridModel(store: try await storage(["savedTabs": stored]))
        await model.performInitialLoad()
        #expect(model.findTab(for: 1)?.previewGeneration == 0)
        model.previewDidUpdate(for: stored[0].id)
        #expect(model.findTab(for: 1)?.previewGeneration == 1)
    }
}
