import App
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import BluetoothNative
import DevicePicker
import Helpers
import JsMessage
import SwiftUI

@main
struct TopazMain: App {
    @State var appModel: AppModel

    init() {
        let deviceSelector = DeviceSelector()
        self.appModel = AppModel(
            messageProcessorFactory: processorFactory(deviceSelector: deviceSelector),
            deviceSelector: deviceSelector,
            storage: debouncedJsonFileStorage()
        )
    }

    var body: some Scene {
        WindowGroup {
            AppContentView(model: appModel)
        }
    }
}

private func debouncedJsonFileStorage() -> CodableStorage {
    DebouncedCodableStorage(JsonDataStorage(FileDataStorage()), debounceInterval: .seconds(2))
}

private func processorFactory(deviceSelector: DeviceSelector) -> JsMessageProcessorFactory {
    JsMessageProcessorFactory(
        builders: [
            BluetoothEngine.handlerName: { _ in
                BluetoothEngine(
                    state: BluetoothState(store: debouncedJsonFileStorage()),
                    client: liveBluetoothClient(),
                    deviceSelector: deviceSelector,
                    enableDebugLogging: appConfig.enableDebugLogging
                )
            },
            JsLogger.handlerName: { _ in
                JsLogger()
            },
        ]
    )
}
