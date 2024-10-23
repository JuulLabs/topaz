import App
import BluetoothClient
import BluetoothNative
import SwiftUI

@main
struct TopazMain: App {
    let appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            AppContentView(model: appModel)
        }
        .environment(\.bluetoothClient, .liveValue)
    }
}
