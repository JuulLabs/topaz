import App
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import BluetoothNative
import DevicePicker
import Helpers
import SwiftUI

@main
struct TopazMain: App {
    @State var appModel = AppModel(
        state: BluetoothState(),
        client: liveBluetoothClient,
        deviceSelector: DeviceSelector(),
        storage: JsonDataStorage(delegate: FileDataStorage(debounceInterval: .seconds(2)))
    )

    var body: some Scene {
        WindowGroup {
            AppContentView(model: appModel)
        }
    }
}
