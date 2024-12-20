import Foundation
import Observation

@MainActor
@Observable
public final class TabGridModel {
    private var tabs: [Tab]

    public init(urls: [URL] = []) {
        // Enumerate, and keep all indices statically bound so that animations are clean.
        // Index zero is reserved for the new-tab cell.
        self.tabs = urls.enumerated().map { (index, url) in
            Tab(index: index + 1, url: url)
        }
    }

    var tabCells: [TabCell] {
        tabs.map(TabCell.tab) + [TabCell.new]
    }

    func deleteButtonTapped(tab: Tab) {
        tabs.removeAll { $0.index == tab.index }
    }

    public func add(url: URL) {
        let tab = Tab(index: tabs.count, url: url)
        tabs.append(tab)
    }
}
