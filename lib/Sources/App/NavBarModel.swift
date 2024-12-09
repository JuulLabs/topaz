import Bluetooth
import Observation
import Settings
import SwiftUI
import WebView

@MainActor
@Observable
public final class NavBarModel {

    let settingsModel: SettingsModel
    let pullDrawer: PullDrawerModel

    let navigator: WebNavigator

    let bluetoothStateStream: AsyncStream<SystemState>

    var fullscreenButtonDisabled: Bool = false
    var isSettingsPresented: Bool = false
    var bluetoothState: SystemState = .unknown
    var shouldShowErrorState: Bool {
        bluetoothState != .unknown && bluetoothState != .poweredOn
    }

    private(set) var isFullscreen: Bool = false

    init(
        navigator: WebNavigator = WebNavigator(),
        bluetoothStateStream: AsyncStream<SystemState> = AsyncStream<SystemState>.makeStream().stream
    ) {
        self.navigator = navigator
        self.pullDrawer = PullDrawerModel(height: 104.0, ratio: 1.25, activationDistance: 16)
        self.settingsModel = SettingsModel()
        self.bluetoothStateStream = bluetoothStateStream
        self.settingsModel.dismiss = { [weak self] in
            self?.isSettingsPresented = false
        }
        self.pullDrawer.disabled = true
        self.pullDrawer.onExtendedPull = { [weak self] in
            self?.pullDrawer.close()
            self?.pullDrawer.disabled = true
            self?.isFullscreen = false
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

    func listenToBluetoothState() async {
        for await state in bluetoothStateStream {
            bluetoothState = state
        }
    }
}
