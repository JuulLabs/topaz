import Observation
import SwiftUI

@MainActor
@Observable
public final class WebLoadingModel: Identifiable, Equatable {
    let freshPageModel: FreshPageModel
    let navBarModel: NavBarModel
    var webContainerModel: WebContainerModel?

    init(
        freshPageModel: FreshPageModel,
        navBarModel: NavBarModel,
        webContainerModel: WebContainerModel? = nil
    ) {
        self.freshPageModel = freshPageModel
        self.navBarModel = navBarModel
        self.webContainerModel = webContainerModel
    }

    var shouldShowFreshPageOverlay: Bool {
        print("shouldShowFreshPageOverlay \(webContainerModel == nil ? "no model yet" : "has model") isLoading=\(webContainerModel?.webPageModel.isPerformingInitialContentLoad == true ? "yes" : "no") \(webContainerModel?.webPageModel.url.isAboutBlank() == true ? "is blank" : "not blank")")
        guard let webContainerModel else { return true }
        return webContainerModel.webPageModel.isPerformingInitialContentLoad || webContainerModel.webPageModel.url.isAboutBlank()
    }

    nonisolated public static func == (lhs: WebLoadingModel, rhs: WebLoadingModel) -> Bool {
        lhs.id == rhs.id
    }
}
