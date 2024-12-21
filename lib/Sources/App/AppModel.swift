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
    let bluetoothEngine: BluetoothEngine
    let state: BluetoothState
    let tabsModel: TabGridModel

    var activePageModels: (WebLoadingModel, SearchBarModel)?

    public init(
        state: BluetoothState,
        client: BluetoothClient,
        deviceSelector: DeviceSelector,
        storage: CodableStorage
    ) {
        self.state = state
        self.storage = storage
        self.deviceSelector = deviceSelector
        self.bluetoothEngine = BluetoothEngine(state: state, client: client, deviceSelector: deviceSelector)
        let tabsModel = TabGridModel(store: storage)
        self.tabsModel = tabsModel

        tabsModel.openNewTab = { [weak self] tabIndex in
            guard let self else { return }
            self.activePageModels = buildPageModels(tabIndex: tabIndex)
        }

        tabsModel.openTab = { [weak self] tab in
            guard let self else { return }
            self.activePageModels = buildPageModels(tabIndex: tab.index, initialUrl: tab.url)
        }

        Task {
            await tabsModel.performInitialLoad()
            if tabsModel.isEmpty {
                self.activePageModels = buildPageModels(tabIndex: 1)
            }
        }
    }

    private func buildPageModels(tabIndex: Int, initialUrl: URL? = nil) -> (WebLoadingModel, SearchBarModel) {
        let searchBarModel = SearchBarModel()
        let freshPageModel = FreshPageModel(searchBarModel: searchBarModel)
        let loadingModel = WebLoadingModel(freshPageModel: freshPageModel)
        if let url = initialUrl {
            freshPageModel.isLoading = true
            freshPageModel.searchBarFocusOnLoad = false
            Task {
                loadingModel.webContainerModel = await self.loadWebContainerModel(tab: tabIndex, url: url, bluetoothStateStream: state.stateStream)
            }
        }
        searchBarModel.onSubmit = { [weak self] url in
            guard let self else { return }
            if let existingModel = loadingModel.webContainerModel {
                existingModel.webPageModel.loadNewPage(url: url)
            } else {
                Task {
                    freshPageModel.isLoading = true
                    if let webContainer = await self.loadWebContainerModel(tab: tabIndex, url: url, bluetoothStateStream: state.stateStream) {
                        loadingModel.webContainerModel = webContainer
                        tabsModel.update(url: url, at: tabIndex)
                    }
                }
            }
        }
        return (loadingModel, searchBarModel)
    }

    private func loadWebContainerModel(tab: Int, url: URL, bluetoothStateStream: AsyncStream<SystemState>) async -> WebContainerModel? {
        do {
            let model = try await WebContainerModel.loadAsync(
                selector: deviceSelector,
                webConfigLoader: webConfigLoader,
                bluetoothStateStream: bluetoothStateStream
            ) { config in
                let model = WebPageModel(
                    tab: tab,
                    url: url,
                    config: config,
                    messageProcessors: [self.bluetoothEngine, jsLogger]
                )
                return model
            }
            model.navBarModel.settingsModel.tabAction = { [weak self] in
                self?.activePageModels = nil
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
