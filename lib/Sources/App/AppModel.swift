import AppMessage
import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import Downloader
import Helpers
import JsMessage
import Navigation
import Observation
import OSLog
import Permissions
import Settings
import SwiftUI
import Tabs
import VirtualKeyboard
import WebKit
import WebView

private let log = Logger(subsystem: "Topaz", category: "AppModel")

@MainActor
@Observable
public class AppModel {
    let storage: CodableStorage
    var webConfigLoader: WebConfigLoader = .init(scriptResourceNames: .topazScripts)
    let deviceSelector: DeviceSelector
    let appDomainProcessors: JsMessageProcessorBuilders
    let enableDebugLogging: Bool
    let tabsModel: TabGridModel

    /// Live (page-loaded) sessions retained across tab switches, bounded by an LRU cap.
    let sessions = TabSessionCache<TabSession>()

    let activeTabState: ActiveTabState

    /// The session currently displayed. A fresh tab lives only here until its first page
    /// load caches it. Nil shows the tab grid, with cached sessions alive underneath.
    var activeSession: TabSession? {
        didSet {
            if oldValue !== activeSession {
                oldValue?.resignFocus()
            }
            activeTabState.setActiveTab(activeSession?.tabIndex)
        }
    }

    /// Sessions kept alive but not displayed. Their web views stay parented, invisible,
    /// so their Js contexts and BLE data processing keep running.
    var backgroundSessions: [TabSession] {
        sessions.allSessions.filter { $0.tabIndex != activeSession?.tabIndex && $0.hasStartedPageLoad }
    }

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
        appDomainProcessors: JsMessageProcessorBuilders,
        deviceSelector: DeviceSelector,
        storage: CodableStorage,
        activeTabState: ActiveTabState = ActiveTabState(),
        enableDebugLogging: Bool = false
    ) {
        self.appDomainProcessors = appDomainProcessors
        self.enableDebugLogging = enableDebugLogging
        self.storage = storage
        self.deviceSelector = deviceSelector
        self.activeTabState = activeTabState
        let tabsModel = TabGridModel(store: storage)
        self.tabsModel = tabsModel

        tabsModel.openNewTab = { [weak self] tabIndex in
            guard let self else { return }
            lastOpenedTabIndex = tabIndex
            self.activeSession = buildSession(tabIndex: tabIndex)
        }

        tabsModel.openTab = { [weak self] tabModel in
            guard let self else { return }
            self.activate(tabIndex: tabModel.index, url: tabModel.url)
        }

        tabsModel.onTabDeleted = { [weak self] tabIndex in
            guard let self else { return }
            // A deleted tab is unreachable: evict now so its BLE connections do not linger
            sessions.evict(tabIndex)
            if lastOpenedTabIndex == tabIndex {
                lastOpenedTabIndex = nil
            }
        }

        Task {
            await PermissionsModel.shared.attachToStorage(self.storage)
            await tabsModel.performInitialLoad()
            if tabsModel.isEmpty {
                var urlFromClipboard: URL?
                if userHasBeenPromptedToPasteUrl == false, UIPasteboard.general.hasURLs {
                    urlFromClipboard = UIPasteboard.general.url
                    userHasBeenPromptedToPasteUrl = true
                }
                self.lastOpenedTabIndex = 1
                self.activeSession = buildSession(tabIndex: 1, initialUrl: urlFromClipboard)
            } else if let lastOpenedTabIndex, let tabModel = tabsModel.findTab(for: lastOpenedTabIndex) {
                self.activate(tabIndex: tabModel.index, url: tabModel.url)
            }
        }
    }

    private func activate(tabIndex: Int, url: URL?) {
        lastOpenedTabIndex = tabIndex
        if let existing = sessions.session(for: tabIndex) {
            // Opener-back belongs only to the window.open flow that installs it,
            // right after this activation returns. The grid, restore-on-launch, and
            // opener-back itself must not resurrect a stale closure that points at a
            // departed opener.
            existing.loadingModel.navBarModel.goBackToPriorPage = nil
            sessions.markActive(tabIndex)
            activeSession = existing
        } else {
            activeSession = buildSession(tabIndex: tabIndex, initialUrl: url)
        }
    }

    private func buildSession(tabIndex: Int, initialUrl: URL? = nil) -> TabSession {
        let loadingModel = buildPageModel(tabIndex: tabIndex, initialUrl: initialUrl)
        let session = TabSession(tabIndex: tabIndex, loadingModel: loadingModel)
        if let url = initialUrl, url.isAboutBlank() == false {
            cache(session)
        }
        return session
    }

    private func cache(_ session: TabSession) {
        sessions.insert(session)
        sessions.markActive(session.tabIndex)
    }

    private func activeSessionDidStartLoad() {
        guard let activeSession else { return }
        cache(activeSession)
    }

    private func goBack(toTabIndex tabIndex: Int) {
        if let tabModel = tabsModel.findTab(for: tabIndex) {
            activate(tabIndex: tabModel.index, url: tabModel.url)
        } else {
            activeSession = nil
        }
    }

    /// Sheds every background session, which reverts each tab to reload-on-revisit, and
    /// leaves the displayed session untouched. The app gives up memory itself rather than
    /// let the system jetsam it wholesale.
    func didReceiveMemoryWarning() {
        sessions.evictAll(except: activeSession?.tabIndex)
    }

    /// Recovery for a tab whose page state is unrecoverable. The web content process was
    /// killed, or the page wedged and overflowed its event delivery buffer. Either way the
    /// Js object graph is gone while the native BLE state survives, so tearing down
    /// converges both sides to empty.
    private func discardAndRebuildSession(tabIndex: Int) {
        let wasDisplayed = activeSession?.tabIndex == tabIndex
        sessions.evict(tabIndex)
        guard wasDisplayed else { return }
        if let tabModel = tabsModel.findTab(for: tabIndex) {
            activeSession = buildSession(tabIndex: tabModel.index, initialUrl: tabModel.url)
        } else {
            activeSession = nil
        }
    }

    /// "Remove all data": tears down every live session, then rebuilds and reloads the
    /// displayed tab from scratch. No page may keep in-memory state - a logged-in DOM,
    /// a Js heap - whose backing storage was just wiped.
    private func resetAllSessionsAfterDataRemoval() {
        let activeTabIndex = activeSession?.tabIndex
        sessions.evictAll()
        guard let activeTabIndex else { return }
        if let tabModel = tabsModel.findTab(for: activeTabIndex) {
            activeSession = buildSession(tabIndex: tabModel.index, initialUrl: tabModel.url)
        }
        // A fresh tab has no grid entry and, with no page load, no state to reset
    }

    private func buildPageModel(tabIndex: Int, initialUrl: URL? = nil) -> WebLoadingModel {
        let navBarModel = buildNavModel(tabIndex: tabIndex)
        let freshPageModel = FreshPageModel(navBarModel: navBarModel)
        let loadingModel = WebLoadingModel(freshPageModel: freshPageModel, navBarModel: navBarModel)
        if let url = initialUrl, url.isAboutBlank() == false {
            performInitialLoad(on: loadingModel, tabIndex: tabIndex, initialUrl: url)
        }
        configureSubmitAction(on: loadingModel, tabIndex: tabIndex)
        return loadingModel
    }

    private func buildNavModel(tabIndex: Int) -> NavBarModel {
        let settingsModel = SettingsModel { [weak self] in
            self?.lastOpenedTabIndex = nil
            self?.activeSession = nil
        }
        settingsModel.onRemoveAllData = { [weak self] in
            self?.resetAllSessionsAfterDataRemoval()
        }
        let navigator = WebNavigator()
        let searchBarModel = SearchBarModel(navigator: navigator)
        navigator.onPageLoaded = { [weak self, weak searchBarModel] url, title in
            guard shouldShowUrl(url) else { return }
            settingsModel.shareItem = SharingUrl(url: url, subject: title)
            self?.tabsModel.update(url: url, at: tabIndex)
            searchBarModel?.searchString = url.absoluteString
            navigator.isInSearchMode = false
        }
        navigator.launchNewPage = { [weak self] newUrl in
            guard let self else { return }
            // The opener is the tab that owns this nav model, not necessarily the
            // displayed one. A background session stays live and can call window.open.
            let openerTabIndex = tabIndex
            let newTab = self.tabsModel.findOrCreateTab(for: newUrl)
            self.activate(tabIndex: newTab.index, url: newTab.url)
            if openerTabIndex != newTab.index {
                self.activeSession?.loadingModel.navBarModel.goBackToPriorPage = { [weak self] in
                    self?.goBack(toTabIndex: openerTabIndex)
                }
            }
        }
        return NavBarModel(navigator: navigator, settingsModel: settingsModel, searchBarModel: searchBarModel, isFullscreen: lastOpenedTabWasInFullscreenMode ?? false) { newValue in
            self.lastOpenedTabWasInFullscreenMode = newValue
        }
    }

    private func performInitialLoad(on loadingModel: WebLoadingModel, tabIndex: Int, initialUrl url: URL) {
        loadingModel.freshPageModel.isLoading = true
        loadingModel.freshPageModel.searchBarFocusOnLoad = false
        loadingModel.navBarModel.searchBarModel.searchString = url.absoluteString
        Task {
            let webContainerModel = await self.loadWebContainerModel(tab: tabIndex, url: url, navBarModel: loadingModel.navBarModel)
            // The session may have been evicted, or replaced, while the config
            // loaded. Do not populate an orphaned session with a container graph
            // nobody owns.
            guard self.isCurrentSessionModel(loadingModel, tabIndex: tabIndex) else { return }
            loadingModel.webContainerModel = webContainerModel
        }
    }

    private func isCurrentSessionModel(_ loadingModel: WebLoadingModel, tabIndex: Int) -> Bool {
        if activeSession?.loadingModel === loadingModel {
            return true
        }
        return sessions.session(for: tabIndex)?.loadingModel === loadingModel
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
                        // Populating a deleted tab would orphan the container and
                        // resurrect the grid entry for the tab.
                        guard self.isCurrentSessionModel(loadingModel, tabIndex: tabIndex) else { return }
                        loadingModel.webContainerModel = webContainer
                        tabsModel.update(url: url, at: tabIndex)
                        if self.activeSession?.loadingModel === loadingModel {
                            self.activeSessionDidStartLoad()
                        }
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
        let virtualKeyboardModel = VirtualKeyboardModel()
        let webPageModel = WebPageModel(
            tab: tab,
            url: url,
            config: config,
            navigator: navBarModel.navigator,
            virtualKeyboardModel: virtualKeyboardModel
        )
        webPageModel.attach(messageProcessorFactory: makeProcessorFactory(for: webPageModel, virtualKeyboard: virtualKeyboardModel))
        webPageModel.onWebContentProcessTerminated = { [weak self] in
            self?.discardAndRebuildSession(tabIndex: tab)
        }
        webPageModel.onEventDeliveryOverflow = { [weak self] in
            self?.discardAndRebuildSession(tabIndex: tab)
        }
        return WebContainerModel(webPageModel: webPageModel, navBarModel: navBarModel, selector: deviceSelector, virtualKeyboard: virtualKeyboardModel)
    }

    /// Builds this tab's processor factory by merging the app-domain builders with page-coupled
    /// builders that capture this page's collaborators. Each builder still constructs a fresh
    /// processor per JS context, so cross-origin teardown semantics are preserved.
    private func makeProcessorFactory(for page: WebPageModel, virtualKeyboard: VirtualKeyboardModel) -> JsMessageProcessorFactory {
        let debugLogging = enableDebugLogging
        var builders = appDomainProcessors
        builders[AppMessageProcessor.handlerName] = { [weak page, debugLogging] _ in
            AppMessageProcessor(host: WebPageAppMessageHost(page: page), enableDebugLogging: debugLogging)
        }
        builders[VirtualKeyboard.handlerName] = { [virtualKeyboard, debugLogging] _ in
            VirtualKeyboard(viewModel: virtualKeyboard, enableDebugLogging: debugLogging)
        }
        return JsMessageProcessorFactory(builders: builders)
    }
}

private func shouldShowUrl(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased() else {
        return false
    }
    return !["about", "data"].contains(scheme)
}
