import BluetoothClient
import Design
import DevicePicker
import SwiftUI
import WebView

public struct AppContentView: View {
    @Environment(\.bluetoothClient) var bluetoothClient

    let model: AppModel

    public init(
        model: AppModel
    ) {
        self.model = model
        registerFonts()
    }

    public var body: some View {
        WebLoadingView(model: model.loadingModel)
        .task {
            // TODO: a more rigourous DI mechanism
            let state = BluetoothState()
            let selector = DeviceSelector()
#if targetEnvironment(simulator)
            let client: BluetoothClient = .clientWithMockAds(selector: selector)
            model.injectDependencies(state: state, bluetoothClient: client, selector: selector)
#else
            model.injectDependencies(state: state, bluetoothClient: bluetoothClient, selector: selector)
#endif
        }
    }
}

#Preview("FreshTab") {
    AppContentView(model: AppModel())
        .environment(\.bluetoothClient, .mockClient())
}

#Preview("Content") {
    let model = AppModel()
    AppContentView(model: model)
        .environment(\.bluetoothClient, .mockClient())
        .task {
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
            let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
            model.freshPageModel.searchBarModel.onSubmit(url)
        }
}
