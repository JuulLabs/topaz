import Observation
import SwiftUI

@MainActor
@Observable
public final class FreshPageModel {
    let searchBarModel: SearchBarModel
    var isLoading: Bool
    var searchBarFocusOnLoad: Bool

    init(
        searchBarModel: SearchBarModel,
        isLoading: Bool = false,
        searchBarFocusOnLoad: Bool = true
    ) {
        self.searchBarModel = searchBarModel
        self.isLoading = isLoading
        self.searchBarFocusOnLoad = searchBarFocusOnLoad
    }

    func onAppear() {
        if searchBarFocusOnLoad {
            searchBarModel.focusedField = .searchBar
        }
    }
}
