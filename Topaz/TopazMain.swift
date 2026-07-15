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
        BluetoothSystemState.shared.requestPowerOn = liveBluetoothPowerRequest
        let deviceSelector = DeviceSelector()
        let activeTabState = ActiveTabState()
        self.appModel = AppModel(
            appDomainProcessors: appDomainProcessors(deviceSelector: deviceSelector, activeTabState: activeTabState),
            deviceSelector: deviceSelector,
            storage: debouncedJsonFileStorage(),
            activeTabState: activeTabState,
            enableDebugLogging: appConfig.enableDebugLogging
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
private func appDomainProcessors(deviceSelector: DeviceSelector, activeTabState: ActiveTabState) -> JsMessageProcessorBuilders {
    [
        BluetoothEngine.handlerName: { context in
            let eventBus = EventBus(enableDebugLogging: appConfig.enableDebugLogging)
            return BluetoothEngine(
                eventBus: eventBus,
                state: BluetoothState(securityList: .shared, store: debouncedJsonFileStorage()),
                client: liveBluetoothClient(eventBus: eventBus),
                // Device selection is only permitted for the tab the user is looking
                // at; background tabs fail fast with a page-visibility error
                deviceSelector: TabGatedDeviceSelector(
                    tab: context.id.tab,
                    activeTabState: activeTabState,
                    wrapping: deviceSelector
                ),
                enableDebugLogging: appConfig.enableDebugLogging
            )
        },
        JsLogger.handlerName: { _ in
            JsLogger()
        },
    ]
}
