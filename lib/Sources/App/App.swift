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
        VStack {
            if let webModel = model.webContainerModel {
                WebContainerView(model: webModel)
            } else {
                FreshPageView(searchBarModel: model.searchBarModel)
            }
        }
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

#Preview {
    AppContentView(model: AppModel())
        .environment(\.bluetoothClient, .mockClient())
}
