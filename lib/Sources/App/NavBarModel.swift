import Navigation
import Observation
import Settings
import SwiftUI
import WebView
import UIHelpers

@MainActor
@Observable
public final class NavBarModel {

    let searchBarModel: SearchBarModel
    let settingsModel: SettingsModel
    let pullDrawer: PullDrawerModel

    let navigator: WebNavigator
    let keyboardObserver: KeyboardObserver

    var fullscreenButtonDisabled: Bool = false
    var isSettingsPresented: Bool = false
    
    var navBarYOffset: CGFloat = 0
    
    @ObservationIgnored
    private var previousKeyboardFrame: CGRect?

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
        self.keyboardObserver = .init()
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

    var backButtonDisabled: Bool {
        navigator.canGoBack == false
    }

    var forwardButtonDisabled: Bool {
        navigator.canGoForward == false
    }

    // TODO: This is a hack. It's correcting for a possible bug in SwiftUI that incorrectly adjusts
    // the height of the safe area after a web view text field loses focus.
    func task() async {
        for await frame in keyboardObserver.stream() {
            guard Task.isCancelled == false else {
                keyboardObserver.endStream()
                return
            }
            if let frame, let previousKeyboardFrame, previousKeyboardFrame.height > frame.height {
                navBarYOffset = -(previousKeyboardFrame.height - frame.height)
            } else {
                navBarYOffset = 0
            }
            previousKeyboardFrame = frame
        }
    }
    
    func backButtonTapped() {
        navigator.goBack()
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
