import Observation
import SwiftUI

@MainActor
@Observable
public final class SearchEngineSelectorModel {
    let storage: SettingsStorage
    let headerText: String
    let rows: [SearchEngineProvider]

    private(set) var isExpanded: Bool = true
    private(set) var selectedRowId: String?

    public init(
        headerText: String = "Default search page",
        rows: [SearchEngineProvider] = defaultSearchEngines,
        storage: SettingsStorage = .shared
    ) {
        self.headerText = headerText
        self.rows = rows
        self.storage = storage
        loadInitialState()
    }

    private func loadInitialState() {
        isExpanded = storage.object(forKey: .searchEngineSectionExpandedKey) ?? true
        selectedRowId = storage.object(forKey: .preferredSearchEngineIdKey) ?? rows.first?.id
    }

    func headerButtonTapped() {
        withAnimation {
            isExpanded.toggle()
            storage.set(value: isExpanded, forKey: .searchEngineSectionExpandedKey)
        }
    }

    func rowButtonTapped(_ rowId: String) {
        selectedRowId = rows.first(where: { $0.id == rowId })?.id
        if let selectedRowId {
            storage.set(value: selectedRowId, forKey: .preferredSearchEngineIdKey)
        }
    }
}

extension String {
    static let searchEngineSectionExpandedKey = "SearchEngineSectionExpanded"
}
