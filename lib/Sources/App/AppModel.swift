import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import Helpers
import JsMessage
import Observation
import SwiftUI
import Tabs
import WebView

@MainActor
@Observable
public class AppModel {
    let storage: CodableStorage
    var webConfigLoader: WebConfigLoader = .init(scriptResourceNames: .topazScripts)
    let deviceSelector: DeviceSelector
    let messageProcessorFactory: JsMessageProcessorFactory
    let tabsModel: TabGridModel

    var activePageModel: WebLoadingModel?

    public init(
        messageProcessorFactory: JsMessageProcessorFactory,
        deviceSelector: DeviceSelector,
        storage: CodableStorage
    ) {
        self.messageProcessorFactory = messageProcessorFactory
        self.storage = storage
        self.deviceSelector = deviceSelector
        let tabsModel = TabGridModel(store: storage)
        self.tabsModel = tabsModel

        tabsModel.openNewTab = { [weak self] tabIndex in
            guard let self else { return }
            self.activePageModel = buildPageModel(tabIndex: tabIndex)
        }

        tabsModel.openTab = { [weak self] tab in
            guard let self else { return }
            self.activePageModel = buildPageModel(tabIndex: tab.index, initialUrl: tab.url)
        }

        Task {
            await tabsModel.performInitialLoad()
            if tabsModel.isEmpty {
                self.activePageModel = buildPageModel(tabIndex: 1)
            }
        }
    }

    private func buildPageModel(tabIndex: Int, initialUrl: URL? = nil) -> WebLoadingModel? {
        let navBarModel = NavBarModel()
        let freshPageModel = FreshPageModel(searchBarModel: navBarModel.searchBarModel)
        let loadingModel = WebLoadingModel(freshPageModel: freshPageModel, navBarModel: navBarModel)
        if let url = initialUrl {
            freshPageModel.isLoading = true
            freshPageModel.searchBarFocusOnLoad = false
            Task {
                loadingModel.webContainerModel = await self.loadWebContainerModel(tab: tabIndex, url: url, navBarModel: navBarModel)
            }
        }
        navBarModel.searchBarModel.onSubmit = { [weak self, weak navBarModel, weak loadingModel] url in
            guard let self, let navBarModel, let loadingModel else { return }
            if let existingModel = loadingModel.webContainerModel {
                existingModel.webPageModel.loadNewPage(url: url)
            } else {
                Task {
                    freshPageModel.isLoading = true
                    if let webContainer = await self.loadWebContainerModel(tab: tabIndex, url: url, navBarModel: navBarModel) {
                        loadingModel.webContainerModel = webContainer
                        tabsModel.update(url: url, at: tabIndex)
                    }
                }
            }
        }
        return loadingModel
    }

    private func loadWebContainerModel(tab: Int, url: URL, navBarModel: NavBarModel) async -> WebContainerModel? {
        do {
            let model = try await WebContainerModel.loadAsync(
                selector: deviceSelector,
                navBarModel: navBarModel,
                webConfigLoader: webConfigLoader
            ) { [messageProcessorFactory] config in
                WebPageModel(
                    tab: tab,
                    url: url,
                    config: config,
                    messageProcessorFactory: messageProcessorFactory,
                    navigator: navBarModel.navigator
                )
            }
            model.navBarModel.settingsModel.tabAction = { [weak self] in
                self?.activePageModel = nil
            }
            model.webPageModel.onPageLoaded = { [weak self] url in
                self?.tabsModel.update(url: url, at: tab)
            }
            return model
        } catch {
            // TODO: navigate away due to failure and try again
            print("Unable to load \(error)")
            return nil
        }
    }
}
