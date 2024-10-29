import BluetoothClient
import DevicePicker
import Observation
import SwiftUI
import WebView

struct WebContainerView: View {
    @Bindable var model: WebContainerModel

    var body: some View {
        WebPageView(model: model.webPageModel)
            .sheet(isPresented: $model.selector.isSelecting) {
                NavigationStack {
                    DevicePickerView(model: model.pickerModel)
                        .navigationTitle("Select Device")
                }
            }
    }
}

#Preview {
    let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
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
    WebContainerView(
        model: WebContainerModel(
            webPageModel: webPageModel,
            selector: selector
        )
    )
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
