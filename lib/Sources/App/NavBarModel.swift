import Observation
import Settings
import SwiftUI
import WebView

@MainActor
@Observable
public final class NavBarModel {

    let settingsModel: SettingsModel

    let navigator: WebNavigator

    var fullscreenButtonDisabled: Bool = false
    var isFullscreen: Bool = false
    var isSettingsPresented: Bool = false

    init(
        navigator: WebNavigator = WebNavigator()
    ) {
        self.navigator = navigator
        self.settingsModel = SettingsModel()
        self.settingsModel.dismiss = { [weak self] in
            self?.isSettingsPresented = false
        }
    }

    var backButtonDisabled: Bool {
        navigator.canGoBack == false
    }

    var forwardButtonDisabled: Bool {
        navigator.canGoForward == false
    }

    func backButtonTapped() {
        navigator.goBack()
    }

    func forwardButtonTapped() {
        navigator.goForward()
    }

    func fullscreenButtonTapped() {
        isFullscreen.toggle()
    }

    func settingsButtonTapped() {
        isSettingsPresented.toggle()
    }

    func deriveProgress(loadingState: WebPageLoadingState) -> Float? {
        switch loadingState {
        case .initializing:
            return 0.0
        case let .inProgress(progress):
            return progress
        case .complete:
            return nil
        }
    }
}
