import BluetoothClient
import BluetoothEngine
import DevicePicker
import Effector
import Observation
import SwiftUI
import WebView
import WebKit

struct WebContainerView: View {
    @Bindable var model: WebContainerModel

    var body: some View {
        WebPageView(model: model.webPageModel)
            .overlay {
                // TODO: temporary for demo only - move this to the navigation panel
                if case let .inProgress(progress) = model.webPageModel.loadingState {
                    ProgressView(value: progress)
                        .tint(.white)
                        .frame(minHeight: 40)
                        .background(Color.topaz600)
                        .offset(y: 300)
                }
            }
            .sheet(isPresented: $model.selector.isSelecting) {
                NavigationStack {
                    DevicePickerView(model: model.pickerModel)
                        .navigationTitle("Select Device")
                }
            }
    }
}

#Preview("DevicePicker") {
    WebContainerView(
        model: previewModel()
    )
}

@MainActor
private func previewModel() -> WebContainerModel {
    let url = URL(string: "https://googlechrome.github.io/samples/web-bluetooth/device-info.html")!
    let selector = DeviceSelector()
#if targetEnvironment(simulator)
    let client: BluetoothClient = .clientWithMockAds(selector: selector)
#else
    let client: BluetoothClient = .testValue
#endif
    let bluetoothEngine = BluetoothEngine(
        state: BluetoothState(),
        effector: .liveValue(client: client.request),
        deviceSelector: selector,
        client: client
    )
    let webPageModel = WebPageModel(
        tab: 0,
        url: url,
        config: previewWebConfig(),
        messageProcessors: [bluetoothEngine]
    )
    return WebContainerModel(
        webPageModel: webPageModel,
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
extension BluetoothClient {
    nonisolated static public func clientWithMockAds(selector: DeviceSelector) -> BluetoothClient {
        var injectionTask: Task<Void, Never>?
        return .mockClient(
            systemState: { .poweredOn },
            startScanning: { _ in
                Task { @MainActor in
                    injectionTask = selector.injectMockAds()
                }
            },
            stopScanning: {
                Task { @MainActor in
                    injectionTask?.cancel()
                }
            }
        )
    }
}
#endif
