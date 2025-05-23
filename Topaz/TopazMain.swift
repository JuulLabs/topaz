import App
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import BluetoothNative
import DevicePicker
import EventBus
import Helpers
import JsMessage
import SecurityList
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
    DebouncedCodableStorage(JsonDataStorage(FileDataStorage()), debounceInterval: .seconds(1))
}

private func processorFactory(deviceSelector: DeviceSelector) -> JsMessageProcessorFactory {
    JsMessageProcessorFactory(
        builders: [
            BluetoothEngine.handlerName: { _ in
                let eventBus = EventBus()
                return BluetoothEngine(
                    eventBus: eventBus,
                    state: BluetoothState(securityList: .shared, store: debouncedJsonFileStorage()),
                    client: liveBluetoothClient(eventBus: eventBus),
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
