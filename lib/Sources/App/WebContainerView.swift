import BluetoothClient
import DevicePicker
import Observation
import SwiftUI
import WebView
import WebKit

struct WebContainerView: View {
    @Bindable var model: WebContainerModel
    let config: WKWebViewConfiguration

    var body: some View {
        WebPageView(model: model.webPageModel, config: config)
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

#Preview {
    WebContainerView(
        model: previewModel(),
        config: previewWebConfig()
    )
}

@MainActor
private func previewModel() -> WebContainerModel {
    let url = URL(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
    let selector = DeviceSelector()
#if targetEnvironment(simulator)
    let client: BluetoothClient = .clientWithMockAds(selector: selector)
#else
    let client: BluetoothClient = .testValue
#endif
    let bluetoothEngine = BluetoothEngine(
        deviceSelector: selector,
        client: client
    )
    let webPageModel = WebPageModel(
        tab: 0,
        url: url,
        messageProcessors: [bluetoothEngine]
    )
    return WebContainerModel(
        webPageModel: webPageModel,
        selector: selector
    )
}

@MainActor
private func previewWebConfig() -> WKWebViewConfiguration {
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
