import SwiftUI
import WebView

public struct AppContentView: View {

    public init () {}

    let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/availability.html")!


    public var body: some View {
        VStack {
            Text("Topaz")
                .font(.title)
                .padding()
            WebPageView(
                model: WebPageModel(url: url)
            )
        }
    }
}

#Preview {
    AppContentView()
        .environment(
            \.bluetoothClient,
             .mockClient(
                systemState: { .poweredOn }
             )
        )
}
