import App
import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import BluetoothNative
import DevicePicker
import SwiftUI

@main
struct TopazMain: App {
    @State var appModel = AppModel(state: BluetoothState(), client: liveBluetoothClient, deviceSelector: DeviceSelector())

    var body: some Scene {
        WindowGroup {
            AppContentView(model: appModel)
        }
    }
}
