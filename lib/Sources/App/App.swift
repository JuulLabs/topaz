import BluetoothClient
import DevicePicker
import JsMessage
import Observation
import SwiftUI
import WebView

@MainActor
@Observable
public class AppModel {
    var webContainerModel: WebContainerModel?

    public init() {}

    func injectDemoModel(bluetoothClient: BluetoothClient) {
        let selector = DeviceSelector()
        let bluetoothEngine = BluetoothEngine(
            deviceSelector: selector,
            client: bluetoothClient
        )
        let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
        let webPageModel = WebPageModel(
            url: url,
            messageProcessors: [bluetoothEngine]
        )
        webContainerModel = WebContainerModel(
            webPageModel: webPageModel,
            selector: selector
        )
    }
}

public struct AppContentView: View {
    @Environment(\.bluetoothClient) var bluetoothClient

    let model: AppModel

    public init(
        model: AppModel
    ) {
        self.model = model
    }

    public var body: some View {
        VStack {
            Text("Topaz")
                .font(.title)
                .padding()
            if let webModel = model.webContainerModel {
                WebContainerView(model: webModel)
            }
        }
        .task {
            // Testing/Demo
            model.injectDemoModel(bluetoothClient: bluetoothClient)
        }
    }
}

#Preview {
    AppContentView(model: AppModel())
        .environment(\.bluetoothClient, .mockClient())
}
