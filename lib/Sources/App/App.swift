import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import Design
import DevicePicker
import SwiftUI
import WebView

public struct AppContentView: View {
    let model: AppModel

    public init(
        model: AppModel
    ) {
        self.model = model
        registerFonts()
    }

    public var body: some View {
        WebLoadingView(model: model.loadingModel, searchBarModel: model.freshPageModel.searchBarModel)
    }
}

#Preview("FreshTab") {
    AppContentView(model: previewModel())
}

#Preview("Content") {
    let model = previewModel()
    AppContentView(model: model)
        .task {
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
            let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
            model.freshPageModel.searchBarModel.onSubmit(url)
        }
}

@MainActor
private func previewModel() -> AppModel {
    let state = BluetoothState()
    let selector = DeviceSelector()
#if targetEnvironment(simulator)
    let mockClient = MockBluetoothClient.clientWithMockAds(selector: selector)
#else
    let mockClient = MockBluetoothClient()
#endif
    return AppModel(state: state, client: mockClient, deviceSelector: selector)
}
