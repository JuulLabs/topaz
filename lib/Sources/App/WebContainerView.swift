import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import EventBus
import JsMessage
import Observation
import Settings
import SwiftUI
import WebView
import WebKit

struct WebContainerView: View {
    @Bindable var webContainerModel: WebContainerModel

    var body: some View {
        VStack(spacing: 0) {
            WebPageView(model: webContainerModel.webPageModel)
                .webPagePullDrawer(webContainerModel.navBarModel.pullDrawer) {
                    PullDrawerView {
                        webContainerModel.navBarModel.fullscreenButtonTapped()
                    }
                }
            if webContainerModel.shouldShowErrorState {
                BluetoothErrorView(
                    state: webContainerModel.bluetoothSystem.systemState,
                    drawShadow: !webContainerModel.navBarModel.isFullscreen
                )
            }
            if !webContainerModel.navBarModel.isFullscreen {
                NavBarView(model: webContainerModel.navBarModel)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(.smooth), value: webContainerModel.navBarModel.isFullscreen)
        .sheet(isPresented: $webContainerModel.selector.isSelecting) {
            NavigationStack {
                DevicePickerView(model: webContainerModel.pickerModel)
            }
            .accentColor(.white)
        }
        .sheet(isPresented: $webContainerModel.navBarModel.isSettingsPresented) {
            NavigationStack {
                SettingsView(model: webContainerModel.navBarModel.settingsModel)
                    .navigationTitle("Settings")
            }
            .accentColor(.white)
        }
    }
}

#Preview("DevicePicker") {
    WebContainerView(
        webContainerModel: previewModel(state: .poweredOn)
    )
}

#Preview("PoweredOff") {
    WebContainerView(
        webContainerModel: previewModel(state: .poweredOff)
    )
}

@MainActor
private func previewModel(state: SystemState) -> WebContainerModel {
    let url = URL(string: "https://googlechrome.github.io/samples/web-bluetooth/device-info.html")!
    let selector = DeviceSelector()
    let eventBus = EventBus()
#if targetEnvironment(simulator)
    let client = MockBluetoothClient.clientWithMockAds(selector: selector, eventBus: eventBus)
#else
    let client: BluetoothClient = MockBluetoothClient()
#endif
    let bluetoothEngine = BluetoothEngine(
        eventBus: eventBus,
        state: BluetoothState(),
        client: client,
        deviceSelector: selector
    )
    let factory = staticMessageProcessorFactory(
        [BluetoothEngine.handlerName: bluetoothEngine]
    )
    let navBarModel = NavBarModel(tabManagementAction: {}, onFullscreenChanged: { _ in })
    let webPageModel = WebPageModel(
        tab: 0,
        url: url,
        config: previewWebConfig(),
        messageProcessorFactory: factory,
        navigator: navBarModel.navigator
    )
    return WebContainerModel(
        webPageModel: webPageModel,
        navBarModel: navBarModel,
        selector: selector,
        bluetoothSystem: BluetoothSystemState(systemState: state)
    )
}

@MainActor
func previewWebConfig() -> WKWebViewConfiguration {
#if targetEnvironment(simulator)
    return WebConfigLoader.loadImmediate()
#else
    return WKWebViewConfiguration()
#endif
}

#if targetEnvironment(simulator)
extension MockBluetoothClient {
    nonisolated static public func clientWithMockAds(selector: DeviceSelector, eventBus: EventBus) -> BluetoothClient {
        var injectionTask: Task<Void, Never>?
        var client = MockBluetoothClient()
        client.onEnable = {
            eventBus.enqueueEvent(SystemStateEvent(.poweredOn))
        }
        client.onStartScanning = { _ in
            Task { @MainActor in
                injectionTask = selector.injectMockAds()
            }
        }
        client.onStopScanning = {
            Task { @MainActor in
                injectionTask?.cancel()
            }
        }
        return client
    }
}
#endif
