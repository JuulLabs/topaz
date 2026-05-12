import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import Downloader
import EventBus
import JsMessage
import Observation
import Settings
import SwiftUI
import VirtualKeyboard
import WebView
import WebKit

struct WebContainerView: View {
    @Bindable var webContainerModel: WebContainerModel
    @State var navStackHeight: CGFloat = 0.0

    var body: some View {
        ZStack {
            WebPageView(model: webContainerModel.webPageModel)
                .padding(.bottom, navStackHeight)
                .ignoresSafeArea(
                    webContainerModel.virtualKeyboard.overlaysContent ? .keyboard : [],
                    edges: webContainerModel.virtualKeyboard.overlaysContent ? .bottom : []
                )
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    if webContainerModel.shouldShowErrorState {
                        BluetoothErrorView(
                            state: webContainerModel.bluetoothSystem.systemState
                        )
                    }
                    if webContainerModel.shouldShowNavBar {
                        NavBarViewV2(model: webContainerModel.navBarModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                    navStackHeight = height
                }
            }
            if webContainerModel.navBarModel.isSettingsPresented {
                SettingsViewV2(model: webContainerModel.navBarModel.settingsModel)
            }
            if webContainerModel.navBarModel.isFullscreen {
                ExitFullscreenButton {
                    webContainerModel.navBarModel.fullscreenButtonTapped()
                }
            }
        }
        .animation(.spring(.smooth), value: webContainerModel.navBarModel.isSettingsPresented)
        .animation(.spring(.smooth), value: webContainerModel.navBarModel.isFullscreen)
        .sheet(isPresented: $webContainerModel.selector.isSelecting) {
            NavigationStack {
                DevicePickerView(model: webContainerModel.pickerModel)
            }
            .accentColor(.white)
        }
        .sheet(isPresented: $webContainerModel.webPageModel.isDownloadsPresented) {
            NavigationStack {
                DownloadListView(model: Downloads.shared)
                    .navigationTitle("Downloads")
            }
            .presentationDetents([.medium])
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

#Preview("VirtualKeyboard") {
    @Previewable @State var model = previewModel(
        state: .poweredOn,
        url: URL(string: "https://googlechrome.github.io/samples/virtualkeyboard/")!
    )
    VStack {
        Button("overlaysContent = \(model.virtualKeyboard.overlaysContent ? "true" : "false")", action: {
            model.virtualKeyboard.overlaysContent.toggle()
        })
        WebContainerView(webContainerModel: model)
    }
}

@MainActor
private func previewModel(state: SystemState, url: URL? = nil) -> WebContainerModel {
    let url = url ?? URL(string: "https://googlechrome.github.io/samples/web-bluetooth/device-info.html")!
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
    let navBarModel = NavBarModel(settingsModel: SettingsModel(), onFullscreenChanged: { _ in })
    let virtualKeyboard = VirtualKeyboardModel()
    let webPageModel = WebPageModel(
        tab: 0,
        url: url,
        config: previewWebConfig(),
        messageProcessorFactory: factory,
        navigator: navBarModel.navigator,
        virtualKeyboardModel: virtualKeyboard
    )
    return WebContainerModel(
        webPageModel: webPageModel,
        navBarModel: navBarModel,
        selector: selector,
        virtualKeyboard: virtualKeyboard,
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
@MainActor
private final class MainActorTaskHolder {
    var task: Task<Void, Never>?
}

extension MockBluetoothClient {
    nonisolated static public func clientWithMockAds(selector: DeviceSelector, eventBus: EventBus) -> BluetoothClient {
        let taskHolder = MainActor.assumeIsolated { MainActorTaskHolder() }
        var client = MockBluetoothClient()
        client.onEnable = {
            eventBus.enqueueEvent(SystemStateEvent(.poweredOn))
        }
        client.onStartScanning = { _ in
            Task { @MainActor in
                taskHolder.task = selector.injectMockAds()
            }
        }
        client.onStopScanning = {
            Task { @MainActor in
                taskHolder.task?.cancel()
            }
        }
        return client
    }
}
#endif
