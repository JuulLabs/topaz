import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
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
    let client = MockBluetoothClient.clientWithMockAds(selector: selector)
#else
    let client: BluetoothClient = MockBluetoothClient()
#endif
    let bluetoothEngine = BluetoothEngine(
        state: BluetoothState(),
        client: client,
        deviceSelector: selector
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
