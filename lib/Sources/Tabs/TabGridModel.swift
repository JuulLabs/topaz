import Foundation
import Helpers
import Observation

@MainActor
@Observable
public final class TabGridModel {
    private let store: CodableStorage?
    private var tabs: [Int: TabModel]

    public var openTab: (TabModel) -> Void = { _ in }
    public var openNewTab: (Int) -> Void = { _ in }

    init(urls: [URL] = []) {
        self.store = nil
        self.tabs = Self.urlsToTabs(urls)
    }

    public init(store: CodableStorage) {
        self.store = store
        self.tabs = [:]
    }

    var tabCells: [TabCell] {
        sortedTabs.map(TabCell.tab) + [TabCell.new]
    }

    var urls: [URL] { sortedTabs.map(\.url) }

    private var sortedTabs: [TabModel] { tabs.values.sorted(by: { $0.index < $1.index }) }

    private static func urlsToTabs(_ urls: [URL]) -> [Int: TabModel] {
        // Enumerate, and keep all indices statically bound so that animations are clean.
        // Index zero is reserved for the new-tab cell.
        urls.enumerated().reduce(into: [:]) { result, pair in
            let index = pair.0 + 1
            result[index] = TabModel(index: index, url: pair.1)
        }
    }

    func tabButtonTapped(tab: TabModel) {
        openTab(tab)
    }

    func newTabButtonTapped() {
        let nextIndex = (tabs.keys.max() ?? 0) + 1
        openNewTab(nextIndex)
    }

    func deleteButtonTapped(tab: TabModel) {
        tabs.removeValue(forKey: tab.index)
        saveAll()
    }

    public func performInitialLoad() async {
        if let urls: [URL] = try? await store?.load(for: .tabURLsKey) {
            self.tabs = Self.urlsToTabs(urls)
        }
    }

    // TODO: store a thumbnail image for the rendered URL content
    public func update(url: URL, at index: Int) {
        tabs[index] = TabModel(index: index, url: url)
        saveAll()
    }

    public var isEmpty: Bool { tabs.isEmpty }

    private func saveAll() {
        guard let store else { return }
        Task { [urls] in
            try await store.save(urls, for: .tabURLsKey)
        }
    }
}

fileprivate extension String {
    static let tabURLsKey = "savedTabURLs"
}
