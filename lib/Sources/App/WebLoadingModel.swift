import Observation
import SwiftUI

@MainActor
@Observable
public final class WebLoadingModel {
    let freshPageModel: FreshPageModel
    var webContainerModel: WebContainerModel?

    init(
        freshPageModel: FreshPageModel,
        webContainerModel: WebContainerModel? = nil
    ) {
        self.freshPageModel = freshPageModel
        self.webContainerModel = webContainerModel
    }

    var shouldShowFreshPageOverlay: Bool {
        guard let webContainerModel else { return true }
        return webContainerModel.webPageModel.isPerformingInitialContentLoad
    }
}
