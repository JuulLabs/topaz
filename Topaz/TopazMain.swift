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
import VirtualKeyboard

@main
struct TopazMain: App {
    @State var appModel: AppModel

    init() {
        let deviceSelector = DeviceSelector()
        self.appModel = AppModel(
            appDomainProcessors: appDomainProcessors(deviceSelector: deviceSelector),
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

/// App-domain processor builders: standalone systems that only need app-wide dependencies.
/// Page-coupled processors (e.g. AppMessage) are merged in per page by `AppModel`.
private func appDomainProcessors(deviceSelector: DeviceSelector) -> JsMessageProcessorBuilders {
    [
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
}
