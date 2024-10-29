import BluetoothClient
import DevicePicker
import SwiftUI
import WebKit

import JsMessage

public struct WebPageView: UIViewRepresentable {

    private let model: WebPageModel

    public init (model: WebPageModel) {
        self.model = model
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView.init()
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.initialize(webView: webView, model: model)
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
    let bluetoothEngine = BluetoothEngine(
        deviceSelector: DeviceSelector(),
        client: .mockClient(
            systemState: { .poweredOn }
        )
    )
    WebPageView(
        model: WebPageModel(
            tab: 0,
            url: url,
            messageProcessors: [bluetoothEngine]
        )
    )
 }
