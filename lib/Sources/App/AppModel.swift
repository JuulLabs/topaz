import BluetoothClient
import DevicePicker
import Helpers
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

    let freshPageModel: FreshPageModel
    let loadingModel: WebLoadingModel

    public init() {
        let searchBarModel = SearchBarModel()
        let freshPageModel = FreshPageModel(searchBarModel: searchBarModel)
        let loadingModel = WebLoadingModel(freshPageModel: freshPageModel)
        self.freshPageModel = freshPageModel
        self.loadingModel = loadingModel
        searchBarModel.onSubmit = { [weak self] url in
            guard let self else { return }
            if let existingModel = loadingModel.webContainerModel {
                existingModel.webPageModel.loadNewPage(url: url)
            } else {
                Task {
                    freshPageModel.isLoading = true
                    await loadWebContainerModel(tab: 0, url: url)
                }
            }
        }
    }

    private func loadWebContainerModel(tab: Int, url: URL) async {
        do {
            self.loadingModel.webContainerModel = try await WebContainerModel.loadAsync(
                selector: deviceSelector,
                webConfigLoader: webConfigLoader
            ) { config in
                WebPageModel(
                    tab: tab,
                    url: url,
                    config: config,
                    messageProcessors: [self.bluetoothEngine, jsLogger]
                )
            }
        } catch {
            // TODO: navigate away due to failure and try again
            print("Unable to load \(error)")
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
