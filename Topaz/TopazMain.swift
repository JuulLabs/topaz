import App
import AppMessage
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
import VirtualKeyboard

@main
struct TopazMain: App {
    @State var appModel: AppModel

    init() {
        let appMessageProcessor = AppMessageProcessor(enableDebugLogging: appConfig.enableDebugLogging)
        let deviceSelector = DeviceSelector()
        self.appModel = AppModel(
            messageProcessorFactory: processorFactory(appMessageProcessor: appMessageProcessor, deviceSelector: deviceSelector),
            appMessageProcessor: appMessageProcessor,
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

private func processorFactory(
    appMessageProcessor: AppMessageProcessor,
    deviceSelector: DeviceSelector
) -> JsMessageProcessorFactory {
    JsMessageProcessorFactory(
        builders: [
            AppMessageProcessor.handlerName: { _ in
                appMessageProcessor
            },
            BluetoothEngine.handlerName: { _ in
                let eventBus = EventBus(enableDebugLogging: appConfig.enableDebugLogging)
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
            VirtualKeyboard.handlerName: { _ in
                VirtualKeyboard(
                    viewModel: .shared,
                    enableDebugLogging: appConfig.enableDebugLogging
                )
            },
        ]
    )
}
