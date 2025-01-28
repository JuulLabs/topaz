import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
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
        }
        .sheet(isPresented: $webContainerModel.navBarModel.isSettingsPresented) {
            NavigationStack {
                SettingsView(model: webContainerModel.navBarModel.settingsModel)
                    .navigationTitle("Settings")
            }
        }
    }
}

#Preview("DevicePicker") {
    WebContainerView(
        webContainerModel: previewModel()
    )
}

@MainActor
private func previewModel() -> WebContainerModel {
    let url = URL(string: "https://googlechrome.github.io/samples/web-bluetooth/device-info.html")!
    let selector = DeviceSelector()
#if targetEnvironment(simulator)
    let client = MockBluetoothClient.clientWithMockAds(selector: selector)
#else
    let client: BluetoothClient = MockBluetoothClient()
#endif
    let bluetoothEngine = BluetoothEngine(
        state: BluetoothState(),
        client: client,
        deviceSelector: selector
    )
    let factory = staticMessageProcessorFactory(
        [BluetoothEngine.handlerName: bluetoothEngine]
    )
    let navBarModel = NavBarModel()
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
        selector: selector
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
    nonisolated static public func clientWithMockAds(selector: DeviceSelector) -> BluetoothClient {
        var injectionTask: Task<Void, Never>?
        var client = MockBluetoothClient()
        client.onSystemState = { SystemStateEvent(.poweredOn) }
        client.onScan = { _ in
            Task { @MainActor in
                injectionTask = selector.injectMockAds()
            }
            let scanner = MockScanner()
            scanner.continuation.onTermination = { _ in
                Task { @MainActor in
                    injectionTask?.cancel()
                }
            }
            return scanner
        }
        return client
    }
}
#endif
