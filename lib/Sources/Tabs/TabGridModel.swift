import Foundation
import Helpers
import Observation

@MainActor
@Observable
public final class TabGridModel {
    private let store: CodableStorage?
    private var tabs: [Int: TabModel]

    private var nextIndex: Int {
        (tabs.keys.max() ?? 0) + 1
    }

    public var openTab: (TabModel) -> Void = { _ in }
    public var openNewTab: (Int) -> Void = { _ in }
    /// Called after a tab is removed from the grid, so its live session can be torn down
    /// immediately. That session holds a web view, a Js context, and BLE connections.
    public var onTabDeleted: (TabModel) -> Void = { _ in }
    /// Supplies the stored preview thumbnail for a tab, if one was ever captured.
    public var loadPreview: (UUID) async -> Data? = { _ in nil }

    init(urls: [URL] = []) {
        self.store = nil
        self.tabs = Self.storedTabsToTabs(urls.map { StoredTab(url: $0) })
    }

    public init(store: CodableStorage) {
        self.store = store
        self.tabs = [:]
    }

    var tabCells: [TabModel] {
        sortedTabs
    }

    var urls: [URL] { sortedTabs.map(\.url) }

    private var sortedTabs: [TabModel] { tabs.values.sorted(by: { $0.index < $1.index }) }

    private static func storedTabsToTabs(_ storedTabs: [StoredTab]) -> [Int: TabModel] {
        // Enumerate, and keep all indices statically bound so that animations are clean.
        // Index zero is reserved for the new-tab cell.
        storedTabs.enumerated().reduce(into: [:]) { result, pair in
            let index = pair.offset + 1
            result[index] = TabModel(index: index, tabID: pair.element.id, url: pair.element.url)
        }
    }

    func tabButtonTapped(tab: TabModel) {
        openTab(tab)
    }

    func createNewTabButtonTapped() {
        createTab(for: URL(string: "about:blank")!)
    }

    func openNewTabButtonTapped() {
        openNewTab(nextIndex)
    }

    func deleteButtonTapped(tab: TabModel) {
        guard let deleted = tabs.removeValue(forKey: tab.index) else { return }
        saveAll()
        onTabDeleted(deleted)
    }

    public func performInitialLoad() async {
        guard let storedTabs = await loadStoredTabs() else { return }
        self.tabs = Self.storedTabsToTabs(storedTabs)
    }

    /// Reads the current format, falling back to the legacy list of bare URLs, which
    /// predates stable tab identifiers. Tabs restored from the legacy list are minted
    /// fresh identifiers and rewritten in the current format on the next save.
    private func loadStoredTabs() async -> [StoredTab]? {
        if let storedTabs: [StoredTab] = try? await store?.load(for: .tabsKey) {
            return storedTabs
        }
        if let urls: [URL] = try? await store?.load(for: .legacyTabURLsKey) {
            return urls.map { StoredTab(url: $0) }
        }
        return nil
    }

    public func findOrCreateTab(for url: URL) -> TabModel {
        if let tabModel = sortedTabs.first(where: { $0.url == url }) {
            return tabModel
        }
        return createTab(for: url)
    }

    @discardableResult
    private func createTab(for url: URL) -> TabModel {
        let newTabModel = TabModel(index: nextIndex, url: url)
        tabs[newTabModel.index] = newTabModel
        saveAll()
        return newTabModel
    }

    /// Records the tab's current URL. A tab that navigates keeps its identity, and so
    /// keeps its thumbnail until a new capture replaces it.
    public func update(url: URL, at index: Int) {
        if let existing = tabs[index] {
            tabs[index] = TabModel(index: index, tabID: existing.tabID, url: url, previewGeneration: existing.previewGeneration)
        } else {
            tabs[index] = TabModel(index: index, url: url)
        }
        saveAll()
    }

    /// Invalidates the cell's cached image after a new thumbnail lands for the tab.
    public func previewDidUpdate(for tabID: UUID) {
        guard let tab = sortedTabs.first(where: { $0.tabID == tabID }) else { return }
        tabs[tab.index]?.previewGeneration += 1
    }

    public var isEmpty: Bool { tabs.isEmpty }

    public func findTab(for index: Int) -> TabModel? {
        tabs[index]
    }

    private func saveAll() {
        guard let store else { return }
        let storedTabs = sortedTabs.map { StoredTab(id: $0.tabID, url: $0.url) }
        Task {
            try await store.save(storedTabs, for: .tabsKey)
        }
    }
}

struct StoredTab: Codable, Sendable {
    let id: UUID
    let url: URL

    init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
    }
}

fileprivate extension String {
    static let tabsKey = "savedTabs"
    static let legacyTabURLsKey = "savedTabURLs"
}
