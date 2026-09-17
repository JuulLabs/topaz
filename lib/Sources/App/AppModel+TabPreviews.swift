import Tabs
import WebView

/// Tab-grid thumbnails: which page gets captured, and when.
extension AppModel {
    /// Connects the grid to the stored thumbnails, in both directions: cells read them
    /// lazily as they appear, and a landing capture refreshes a cell already on screen.
    func configurePreviewCapture() {
        tabsModel.loadPreview = { [previewCoordinator] tabID in
            await previewCoordinator.loadPreview(for: tabID)
        }
        previewCoordinator.onPreviewStored = { [weak tabsModel] tabID in
            tabsModel?.previewDidUpdate(for: tabID)
        }
    }

    /// Leaving a tab is the moment its thumbnail becomes visible, so refresh it.
    func didLeaveSession(_ session: TabSession?) {
        guard let tabIndex = session?.tabIndex else { return }
        capturePreviewNow(forTabIndex: tabIndex)
    }

    /// The grid is the most likely thing on screen after the app is relaunched from a
    /// terminated state, so refresh the displayed tab's thumbnail on the way out.
    func didEnterBackground() {
        guard let tabIndex = activeSession?.tabIndex else { return }
        capturePreviewNow(forTabIndex: tabIndex)
    }

    func pageDidLoad(tabIndex: Int) {
        guard let tabModel = tabsModel.findTab(for: tabIndex), let page = webPage(forTabIndex: tabIndex) else { return }
        previewCoordinator.pageDidLoad(tabID: tabModel.tabID, page: page)
    }

    func capturePreviewNow(forTabIndex tabIndex: Int) {
        guard let tabModel = tabsModel.findTab(for: tabIndex), let page = webPage(forTabIndex: tabIndex) else { return }
        previewCoordinator.captureNow(tabID: tabModel.tabID, page: page)
    }

    /// The displayed page for a tab, or its live background page. A tab with no live
    /// session has nothing to capture.
    private func webPage(forTabIndex tabIndex: Int) -> WebPageModel? {
        let loadingModel = activeSession?.tabIndex == tabIndex
            ? activeSession?.loadingModel
            : sessions.session(for: tabIndex)?.loadingModel
        return loadingModel?.webContainerModel?.webPageModel
    }
}
