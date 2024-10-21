import App
import BluetoothNative
import SwiftUI

@main
struct TopazMain: App {
    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
        .environment(\.bluetoothClient, .liveValue)
    }
}
