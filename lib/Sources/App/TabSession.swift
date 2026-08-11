import Foundation
import WebView

/// A live tab. Retains the full model graph for one tab: nav bar, fresh page overlay,
/// and the web container. The web container appears after the first page load and holds
/// the model-owned web view, Js context, and message processors. The tab therefore
/// survives backgrounding without a reload or dropped BLE connections.
@MainActor
final class TabSession: Identifiable, LiveTabSession {
    let tabIndex: Int
    let loadingModel: WebLoadingModel

    init(tabIndex: Int, loadingModel: WebLoadingModel) {
        self.tabIndex = tabIndex
        self.loadingModel = loadingModel
    }

    nonisolated var id: Int { tabIndex }

    /// False while the tab is still a fresh page: search bar, no content. A fresh tab
    /// holds no web view and is not worth caching. It enters the session cache only
    /// when a real page load starts.
    var hasStartedPageLoad: Bool {
        loadingModel.webContainerModel != nil
    }

    /// Relinquishes any keyboard focus held by the web content. Called when the tab
    /// stops being the displayed one, so its keyboard cannot linger over the next.
    func resignFocus() {
        loadingModel.webContainerModel?.webPageModel.resignFocus()
    }

    /// Ends the web session. Detaches the script handler and releases the web view.
    /// Detaching shuts down the Bluetooth engine for this tab and disconnects its
    /// peripherals. Idempotent. The URL remains in the grid, so reopening the tab
    /// reloads from scratch.
    func teardown() {
        loadingModel.webContainerModel?.webPageModel.teardown()
    }
}
