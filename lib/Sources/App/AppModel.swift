import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import Helpers
import JsMessage
import Navigation
import Observation
import OSLog
import Settings
import SwiftUI
import Tabs
import WebKit
import WebView

private let log = Logger(subsystem: "App", category: "AppModel")

@MainActor
@Observable
public class AppModel {
    let storage: CodableStorage
    var webConfigLoader: WebConfigLoader = .init(scriptResourceNames: .topazScripts)
    let deviceSelector: DeviceSelector
    let messageProcessorFactory: JsMessageProcessorFactory
    let tabsModel: TabGridModel

    var activePageModel: WebLoadingModel?

    // Tracks the last tab index that was opened, so it is known which tab to return
    // to if the user hits Done on the tab management view
    private var previouslyActivePageIndex: Int?

    @ObservationIgnored
    @AppStorage("userHasBeenPromptedToPasteUrl")
    private var userHasBeenPromptedToPasteUrl: Bool = false

    // Tracks the last view the user was on:
    // TabManagement view if this value is nil
    // The tab view at the index if not nil
    @ObservationIgnored
    @AppStorage("lastOpenedTabIndex")
    private var lastOpenedTabIndex: Int?

    @ObservationIgnored
    @AppStorage("lastOpenedTabWasInFullscreenMode")
    private var lastOpenedTabWasInFullscreenMode: Bool?

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
            lastOpenedTabIndex = tabIndex
            self.activePageModel = buildPageModel(tabIndex: tabIndex)
        }

        tabsModel.openTab = { [weak self] tabModel in
            guard let self else { return }
            lastOpenedTabIndex = tabModel.index
            self.activePageModel = buildPageModel(tabModel: tabModel)
        }

        tabsModel.restoreLastOpenedTab = { [weak self] in
            guard let self else { return }
            if let index = self.previouslyActivePageIndex, let tabModel = tabsModel.findTab(for: index) {
                self.activePageModel = self.buildPageModel(tabModel: tabModel)
            }
        }

        Task {
            await tabsModel.performInitialLoad()
            if tabsModel.isEmpty {
                var urlFromClipboard: URL?
                if userHasBeenPromptedToPasteUrl == false, UIPasteboard.general.hasURLs {
                    urlFromClipboard = UIPasteboard.general.url
                    userHasBeenPromptedToPasteUrl = true
                }
                self.lastOpenedTabIndex = 1
                self.activePageModel = buildPageModel(tabIndex: 1, initialUrl: urlFromClipboard)
            } else if let lastOpenedTabIndex, let tabModel = tabsModel.findTab(for: lastOpenedTabIndex) {
                self.activePageModel = buildPageModel(tabModel: tabModel)
            }
        }
    }

    private func buildPageModel(tabModel: TabModel) -> WebLoadingModel {
        buildPageModel(tabIndex: tabModel.index, initialUrl: tabModel.url)
    }

    private func buildPageModel(tabIndex: Int, initialUrl: URL? = nil) -> WebLoadingModel {
        let navBarModel = buildNavModel(tabIndex: tabIndex)
        let freshPageModel = FreshPageModel(searchBarModel: navBarModel.searchBarModel)
        let loadingModel = WebLoadingModel(freshPageModel: freshPageModel, navBarModel: navBarModel)
        if let url = initialUrl, url.isAboutBlank() == false {
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
            guard shouldShowUrl(url) else { return }
            settingsModel.shareItem = SharingUrl(url: url, subject: title)
            self?.tabsModel.update(url: url, at: tabIndex)
            searchBarModel?.searchString = url.absoluteString
        }
        navigator.launchNewPage = { [weak self] newUrl in
            guard let self else { return }
            let newTab = self.tabsModel.findOrCreateTab(for: newUrl)
            let webLoadingModel = self.buildPageModel(tabModel: newTab)
            self.activePageModel = webLoadingModel
        }
        return NavBarModel(navigator: navigator, settingsModel: settingsModel, searchBarModel: searchBarModel, isFullscreen: lastOpenedTabWasInFullscreenMode ?? false) { [weak self] in
                self?.previouslyActivePageIndex = self?.lastOpenedTabIndex
                self?.lastOpenedTabIndex = nil
                self?.activePageModel = nil
        } onFullscreenChanged: { newValue in
            self.lastOpenedTabWasInFullscreenMode = newValue
        }
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
            let config = try await webConfigLoader.loadConfig()
            return buildWebContainerModel(tab: tab, url: url, navBarModel: navBarModel, config: config)
        } catch {
            // TODO: navigate away due to failure and try again
            log.error("Unable to load \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func buildWebContainerModel(tab: Int, url: URL, navBarModel: NavBarModel, config: WKWebViewConfiguration) -> WebContainerModel {
        let webPageModel = WebPageModel(
            tab: tab,
            url: url,
            config: config,
            messageProcessorFactory: messageProcessorFactory,
            navigator: navBarModel.navigator
        )
        return WebContainerModel(webPageModel: webPageModel, navBarModel: navBarModel, selector: deviceSelector)
    }
}

private func shouldShowUrl(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased() else {
        return false
    }
    return !["about", "data"].contains(scheme)
}
