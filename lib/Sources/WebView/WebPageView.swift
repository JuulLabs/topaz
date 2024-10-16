import BluetoothClient
import SwiftUI
import WebKit


public struct WebPageView: UIViewRepresentable {
    @Environment(\.bluetoothClient) var bluetoothClient

    private let model: WebPageModel

    public init (model: WebPageModel) {
        self.model = model
    }

    public func makeUIView(context: Context) -> WKWebView  {
        let engine = BluetoothEngine(client: bluetoothClient)
        let webView = WKWebView.init()
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.initialize(webView: webView, model: model, engine: engine)
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.update(webView: uiView, model: model)
    }

    public static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.deinitialize(webView: uiView)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

#Preview {
    let url = URL.init(string: "https://googlechrome.github.io/samples/web-bluetooth/availability.html")!
    WebPageView(model: WebPageModel(url: url))
        .environment(
            \.bluetoothClient,
             .mockClient(
                systemState: { .poweredOn }
             )
        )
}
