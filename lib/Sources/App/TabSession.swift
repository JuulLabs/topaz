import Foundation
import WebView

/// A live tab: retains the full model graph for one tab (nav bar, fresh page overlay,
/// and - once a page load has begun - the web container with its model-owned web view,
/// Js context, and message processors) so the tab survives being backgrounded without
/// reloading or dropping BLE connections.
@MainActor
final class TabSession: Identifiable, LiveTabSession {
    let tabIndex: Int
    let loadingModel: WebLoadingModel

    init(tabIndex: Int, loadingModel: WebLoadingModel) {
        self.tabIndex = tabIndex
        self.loadingModel = loadingModel
    }

    nonisolated var id: Int { tabIndex }

    /// False while the tab is still a fresh page (search bar, no content). Fresh tabs
    /// hold no web view and are not worth caching - they only enter the session cache
    /// once a real page load begins.
    var hasStartedPageLoad: Bool {
        loadingModel.webContainerModel != nil
    }

    /// Ends the web session: detaches the script handler (shutting down the tab's
    /// Bluetooth engine and disconnecting its peripherals) and releases the web view.
    /// Idempotent. The tab's URL remains in the grid; reopening reloads from scratch.
    func teardown() {
        loadingModel.webContainerModel?.webPageModel.teardown()
    }
}
