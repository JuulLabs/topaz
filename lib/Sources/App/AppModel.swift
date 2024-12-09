import Bluetooth
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
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
    let deviceSelector: DeviceSelector
    let bluetoothEngine: BluetoothEngine

    let freshPageModel: FreshPageModel
    let loadingModel: WebLoadingModel

    public init(
        state: BluetoothState,
        client: BluetoothClient,
        deviceSelector: DeviceSelector
    ) {
        self.deviceSelector = deviceSelector
        self.bluetoothEngine = BluetoothEngine(state: state, client: client, deviceSelector: deviceSelector)
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
                    await loadWebContainerModel(tab: 0, url: url, bluetoothStateStream: state.stateStream)
                }
            }
        }
    }

    private func loadWebContainerModel(tab: Int, url: URL, bluetoothStateStream: AsyncStream<SystemState>) async {
        do {
            self.loadingModel.webContainerModel = try await WebContainerModel.loadAsync(
                selector: deviceSelector,
                webConfigLoader: webConfigLoader,
                bleStateStream: bluetoothStateStream
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
}
