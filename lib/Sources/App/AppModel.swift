import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import Helpers
import JsMessage
import Observation
import Settings
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

            
            var urlFromClipboard: URL? = nil
            if UIPasteboard.general.hasURLs {
                urlFromClipboard = UIPasteboard.general.url
            }

            if tabsModel.isEmpty {
                self.activePageModel = buildPageModel(tabIndex: 1, initialUrl: urlFromClipboard)
            }
        }
    }

    private func buildPageModel(tabIndex: Int, initialUrl: URL? = nil) -> WebLoadingModel? {
        let navBarModel = buildNavModel(tabIndex: tabIndex)
        let freshPageModel = FreshPageModel(searchBarModel: navBarModel.searchBarModel)
        let loadingModel = WebLoadingModel(freshPageModel: freshPageModel, navBarModel: navBarModel)
        if let url = initialUrl {
            performInitialLoad(on: loadingModel, tabIndex: tabIndex, initialUrl: url)
        }
        configureSubmitAction(on: loadingModel, tabIndex: tabIndex)
        return loadingModel
    }

    private func buildNavModel(tabIndex: Int) -> NavBarModel {
        let settingsModel = SettingsModel()
        let navigator = WebNavigator()
        let searchBarModel = SearchBarModel(navigator: navigator)
        navigator.onPageLoaded = { [weak self, weak searchBarModel] url, title in
            guard !url.isAboutBlank() else { return }
            settingsModel.shareItem = SharingUrl(url: url, subject: title)
            self?.tabsModel.update(url: url, at: tabIndex)
            searchBarModel?.searchString = url.absoluteString
        }
        settingsModel.tabAction = { [weak self] in
            self?.activePageModel = nil
        }
        return NavBarModel(navigator: navigator, settingsModel: settingsModel, searchBarModel: searchBarModel)
    }

    private func performInitialLoad(on loadingModel: WebLoadingModel, tabIndex: Int, initialUrl url: URL) {
        loadingModel.freshPageModel.isLoading = true
        loadingModel.freshPageModel.searchBarFocusOnLoad = false
        loadingModel.navBarModel.searchBarModel.searchString = url.absoluteString
        Task {
            loadingModel.webContainerModel = await self.loadWebContainerModel(tab: tabIndex, url: url, navBarModel: loadingModel.navBarModel)
        }
    }

    private func configureSubmitAction(on loadingModel: WebLoadingModel, tabIndex: Int) {
        loadingModel.navBarModel.searchBarModel.onSubmit = { [weak self, weak loadingModel] url in
            guard let self, let loadingModel else { return }
            if let existingModel = loadingModel.webContainerModel {
                existingModel.webPageModel.loadNewPage(url: url)
            } else {
                Task {
                    loadingModel.freshPageModel.isLoading = true
                    if let webContainer = await self.loadWebContainerModel(tab: tabIndex, url: url, navBarModel: loadingModel.navBarModel) {
                        loadingModel.webContainerModel = webContainer
                        tabsModel.update(url: url, at: tabIndex)
                    }
                }
            }
        }
    }

    private func loadWebContainerModel(tab: Int, url: URL, navBarModel: NavBarModel) async -> WebContainerModel? {
        do {
            return try await WebContainerModel.loadAsync(
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
        } catch {
            // TODO: navigate away due to failure and try again
            print("Unable to load \(error)")
            return nil
        }
    }
}
