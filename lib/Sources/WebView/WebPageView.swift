import BluetoothClient
import DevicePicker
import SwiftUI
import WebKit

public struct WebPageView: UIViewRepresentable {

    private let model: WebPageModel

    public init (model: WebPageModel) {
        self.model = model
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: model.config)
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
    WebPageView(model: previewModel())
 }

@MainActor
private func previewModel() -> WebPageModel {
    let url = URL(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
    let bluetoothEngine = BluetoothEngine(
        state: BluetoothState(),
        deviceSelector: DeviceSelector(),
        client: .mockClient(
            systemState: { .poweredOn }
        )
    )
    return WebPageModel(
        tab: 0,
        url: url,
        config: previewWebConfig(),
        messageProcessors: [bluetoothEngine]
    )
}

@MainActor
private func previewWebConfig() -> WKWebViewConfiguration {
#if targetEnvironment(simulator)
    return WebConfigLoader.loadImmediate()
#else
    return WKWebViewConfiguration()
#endif
}
