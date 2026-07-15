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
        ZStack {
            // Keep-alive underlay: background sessions' web views stay parented in the
            // window (invisible, non-interactive) so WebKit keeps their content
            // processes running and BLE events keep flowing to their pages. Chrome
            // (nav bar, sheets, alerts) is never mounted for background sessions.
            ForEach(model.backgroundSessions) { session in
                if let webContainerModel = session.loadingModel.webContainerModel {
                    WebPageView(model: webContainerModel.webPageModel)
                        .opacity(0.001)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            if let session = model.activeSession {
                WebLoadingView(model: session.loadingModel)
                    .background(Color.backgroundPrimary)
            } else {
                TabGridView(model: model.tabsModel)
            }
        }
        // TODO: This locks the app to light mode. Remove this when we want to support dark mode.
        .preferredColorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            model.didReceiveMemoryWarning()
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
            let searchModel = model.activeSession?.loadingModel.navBarModel.searchBarModel
            searchModel?.searchString = "https://googlechrome.github.io/samples/web-bluetooth/index.html"
            searchModel?.didSubmitSearchString()
        }
}

@MainActor
private func previewModel() -> AppModel {
    let state = BluetoothState()
    let selector = DeviceSelector()
    let eventBus = EventBus()
#if targetEnvironment(simulator)
    let mockClient = MockBluetoothClient.clientWithMockAds(selector: selector, eventBus: eventBus)
#else
    let mockClient = MockBluetoothClient()
#endif
    let bluetoothEngine = BluetoothEngine(
        eventBus: eventBus,
        state: state,
        client: mockClient,
        deviceSelector: selector
    )
    return AppModel(
        appDomainProcessors: [
            BluetoothEngine.handlerName: { _ in bluetoothEngine },
        ],
        deviceSelector: selector,
        storage: InMemoryStorage()
    )
}
