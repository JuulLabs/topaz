import BluetoothClient
import JsMessage
import SwiftUI
import WebView

public struct AppContentView: View {
    @Environment(\.jsMessageProcessors) var messageProcessors

    public init () {}

    let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/availability.html")!


    public var body: some View {
        VStack {
            Text("Topaz")
                .font(.title)
                .padding()
            WebPageView(
                model: WebPageModel(
                    url: url,
                    messageProcessors: messageProcessors
                )
            )
        }
    }
}

#Preview {
    let bluetoothEngine = BluetoothEngine(client: .mockClient(
        systemState: { .poweredOn }
    ))
    AppContentView()
        .environment(\.jsMessageProcessors, [bluetoothEngine])
}
