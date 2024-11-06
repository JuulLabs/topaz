import Observation
import SwiftUI

@MainActor
@Observable
public final class FreshPageModel {
    let searchBarModel: SearchBarModel
    var isLoading: Bool

    init(
        searchBarModel: SearchBarModel,
        isLoading: Bool = false
    ) {
        self.searchBarModel = searchBarModel
        self.isLoading = isLoading
    }
}
