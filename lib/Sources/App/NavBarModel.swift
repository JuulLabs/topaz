import Navigation
import Observation
import Settings
import SwiftUI
import WebView

@MainActor
@Observable
public final class NavBarModel {

    let searchBarModel: SearchBarModel
    let settingsModel: SettingsModel
    let pullDrawer: PullDrawerModel

    let navigator: WebNavigator

    var fullscreenButtonDisabled: Bool = false
    var isSettingsPresented: Bool = false

    private(set) var isFullscreen: Bool = false
    private let onFullscreenChanged: (Bool) -> Void

    init(
        navigator: WebNavigator = WebNavigator(),
        settingsModel: SettingsModel,
        searchBarModel: SearchBarModel? = nil,
        isFullscreen: Bool = false,
        onFullscreenChanged: @escaping (Bool) -> Void
    ) {
        self.navigator = navigator
        self.searchBarModel = searchBarModel ?? SearchBarModel(navigator: navigator)
        self.pullDrawer = PullDrawerModel(height: 104.0, ratio: 1.25, activationDistance: 16)
        self.settingsModel = settingsModel
        self.isFullscreen = isFullscreen
        self.onFullscreenChanged = onFullscreenChanged
        self.settingsModel.dismiss = { [weak self] in
            self?.isSettingsPresented = false
        }
        self.pullDrawer.disabled = !isFullscreen
        self.pullDrawer.onExtendedPull = { [weak self] in
            self?.pullDrawer.close()
            self?.pullDrawer.disabled = true
            self?.isFullscreen = false
            self?.onFullscreenChanged(false)
        }
    }

    var goBackToPriorPage: (() -> Void)?

    var backButtonDisabled: Bool {
        navigator.canGoBack == false && goBackToPriorPage == nil
    }

    var forwardButtonDisabled: Bool {
        navigator.canGoForward == false
    }

    func backButtonTapped() {
        if navigator.canGoBack {
            navigator.goBack()
        } else {
            goBackToPriorPage?()
        }
    }

    func forwardButtonTapped() {
        navigator.goForward()
    }

    func fullscreenButtonTapped() {
        isFullscreen.toggle()
        onFullscreenChanged(isFullscreen)
        if isFullscreen {
            pullDrawer.disabled = false
        } else {
            pullDrawer.close()
            pullDrawer.disabled = true
        }
    }

    func settingsButtonTapped() {
        isSettingsPresented.toggle()
    }

    var progress: Float? {
        switch navigator.loadingState {
        case .initializing:
            return 0.0
        case let .inProgress(progress):
            return progress
        case .complete:
            return nil
        }
    }
}
