import BluetoothClient
import DevicePicker
import JsMessage
import Observation
import SwiftUI
import WebView

@MainActor
@Observable
public class AppModel {
    var webConfigLoader: WebConfigLoader = .init(scriptResourceNames: .topazScripts)
    var deviceSelector: DeviceSelector = .init()
    var bluetoothEngine: BluetoothEngine = .init(deviceSelector: DeviceSelector(), client: .testValue)
    var searchBarModel: SearchBarModel = .init()
    var webContainerModel: WebContainerModel?

    public init() {
        searchBarModel.onSubmit = { [weak self] url in
            guard let self else { return }
            if let existingModel = self.webContainerModel {
                existingModel.webPageModel.loadNewPage(url: url)
            } else {
                let webPageModel = WebPageModel(
                    tab: 0,
                    url: url,
                    messageProcessors: [self.bluetoothEngine, jsLogger]
                )
                self.webContainerModel = WebContainerModel(
                    webPageModel: webPageModel,
                    selector: deviceSelector
                )
            }
        }
    }

    func injectDependencies(
        bluetoothClient: BluetoothClient,
        selector: DeviceSelector
    ) {
        deviceSelector = selector
        bluetoothEngine = BluetoothEngine(
            deviceSelector: selector,
            client: bluetoothClient
        )
    }
}
