import App
import BluetoothClient
import BluetoothNative
import SwiftUI

@main
struct TopazMain: App {
    let bluetoothEngine = BluetoothEngine(client: .liveValue)

    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
        .environment(\.jsMessageProcessors, [bluetoothEngine])
    }
}
