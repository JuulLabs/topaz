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
        ZStack {
            Color.topaz600
            if let webModel = model.webContainerModel {
                WebLoadingView(loader: model.webConfigLoader, model: webModel)
            } else {
                FreshPageView(searchBarModel: model.searchBarModel)
            }
        }
        .edgesIgnoringSafeArea(.all) // TODO: only if full screen
        .task {
            // TODO: a more rigourous DI mechanism
            let selector = DeviceSelector()
#if targetEnvironment(simulator)
            let client: BluetoothClient = .clientWithMockAds(selector: selector)
            model.injectDependencies(bluetoothClient: client, selector: selector)
#else
            model.injectDependencies(bluetoothClient: bluetoothClient, selector: selector)
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
            let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
            model.searchBarModel.onSubmit(url)
        }
}
