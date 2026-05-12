import Observation
import SwiftUI
import UIHelpers

@MainActor
@Observable
public final class FreshPageModel {
    private let keyboardObserver = KeyboardObserver()

    let navBarModel: NavBarModel
    var isLoading: Bool
    var searchBarFocusOnLoad: Bool

    init(
        navBarModel: NavBarModel,
        isLoading: Bool = false,
        searchBarFocusOnLoad: Bool = true
    ) {
        self.navBarModel = navBarModel
        self.isLoading = isLoading
        self.searchBarFocusOnLoad = searchBarFocusOnLoad
    }

    var keyboardPresent: Bool {
        keyboardObserver.frame != nil
    }

    func onAppear() {
        if searchBarFocusOnLoad {
            navBarModel.searchBarModel.focusedField = .searchBar
        }
    }
}
