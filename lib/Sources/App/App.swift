import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import Design
import DevicePicker
import EventBus
import Helpers
import JsMessage
import SwiftUI
import Tabs
import WebView

public struct AppContentView: View {
    let model: AppModel

    public init(
        model: AppModel
    ) {
        self.model = model
        registerFonts()
        UINavigationBar.applyCustomizations()
    }

    public var body: some View {
        if let webLoadingModel = model.activePageModel {
            WebLoadingView(model: webLoadingModel)
        } else {
            TabGridView(model: model.tabsModel)
        }
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
            let searchModel = model.activePageModel?.navBarModel.searchBarModel
            searchModel?.searchString = "https://googlechrome.github.io/samples/web-bluetooth/index.html"
            searchModel?.didSubmitSearchString()
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
    let bluetoothEngine = BluetoothEngine(
        eventBus: EventBus(),
        state: state,
        client: mockClient,
        deviceSelector: selector
    )
    let factory = staticMessageProcessorFactory(
        [BluetoothEngine.handlerName: bluetoothEngine]
    )
    return AppModel(
        messageProcessorFactory: factory,
        deviceSelector: selector,
        storage: InMemoryStorage()
    )
}
