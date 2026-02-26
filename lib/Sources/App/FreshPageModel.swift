import Observation
import SwiftUI

@MainActor
@Observable
public final class FreshPageModel {
//    let searchBarModel: SearchBarModel
    let navBarModel: NavBarModel
    var isLoading: Bool
    var searchBarFocusOnLoad: Bool

    init(
//        searchBarModel: SearchBarModel,
        navBarModel: NavBarModel,
        isLoading: Bool = false,
        searchBarFocusOnLoad: Bool = true
    ) {
//        self.searchBarModel = searchBarModel
        self.navBarModel = navBarModel
        self.isLoading = isLoading
        self.searchBarFocusOnLoad = searchBarFocusOnLoad
    }

    func onAppear() {
        if searchBarFocusOnLoad {
            navBarModel.searchBarModel.focusedField = .searchBar
        }
    }
}
