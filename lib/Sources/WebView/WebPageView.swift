import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import JsMessage
import SwiftUI
import WebKit

public struct WebPageView: View {
    @State private var scrollView: UIScrollView?

    private let model: WebPageModel

    public init(model: WebPageModel) {
        self.model = model
    }

    public var body: some View {
        _WebPageView(model: model, scrollView: $scrollView)
            .id(model.id)
            .preference(key: WebPageScrollViewKey.self, value: scrollView)
    }

    private struct _WebPageView: UIViewRepresentable {
        @Binding private var scrollView: UIScrollView?

        private let model: WebPageModel

        init (model: WebPageModel, scrollView: Binding<UIScrollView?>) {
            self.model = model
            self._scrollView = scrollView
        }

        func makeUIView(context: Context) -> WKWebView {
            let webView = model.createWebView()
#if DEBUG
            webView.isInspectable = true
#endif
            context.coordinator.initialize(webView: webView, model: model)
            Task { @MainActor in
                scrollView = webView.scrollView
            }
            return webView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            context.coordinator.update(webView: uiView, model: model)
        }

        static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
            coordinator.deinitialize(webView: uiView)
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
    }
}

struct WebPageScrollViewKey: PreferenceKey {
    static let defaultValue: UIScrollView? = nil
    static func reduce(value: inout UIScrollView?, nextValue: () -> UIScrollView?) {
        value = nextValue()
    }
}

#Preview {
    WebPageView(model: previewModel())
 }

@MainActor
private func previewModel() -> WebPageModel {
    let url = URL(string: "https://googlechrome.github.io/samples/web-bluetooth/index.html")!
    var client = MockBluetoothClient()
    client.onSystemState = { SystemStateEvent(.poweredOn) }
    let bluetoothEngine = BluetoothEngine(
        state: BluetoothState(),
        client: client,
        deviceSelector: DeviceSelector()
    )
    let factory = staticMessageProcessorFactory(
        [BluetoothEngine.handlerName: bluetoothEngine]
    )
    return WebPageModel(
        tab: 0,
        url: url,
        config: previewWebConfig(),
        messageProcessorFactory: factory,
        navigator: WebNavigator()
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
