import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import EventBus
import JsMessage
import Navigation
import SwiftUI
import WebKit

/// Bare host for a model-owned web view.
///
/// The model layer owns the web view, its delegates, and its script handlers, and they
/// survive this view unmounting. Mounting re-parents the web view. Instances come and
/// go as the web view moves between the visible tab and the keep-alive underlay. Never
/// two at once for the same model.
public struct WebPageView: View {
    @State private var scrollView: UIScrollView?

    let model: WebPageModel

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

        // Each representable gets its own container, and the shared, model-owned web
        // view is re-parented between containers. SwiftUI only ever owns the container.
        // Host teardown ordering during a tab switch can therefore never rip the web
        // view out of its new host.
        func makeUIView(context: Context) -> WebPageHostUIView {
            let container = WebPageHostUIView()
            // A torn-down model yields no web view. The empty container is a
            // placeholder until SwiftUI removes this stale host.
            guard let webView = model.webView() else { return container }
            container.host(webView)
            Task { @MainActor in
                scrollView = webView.scrollView
            }
            return container
        }

        func updateUIView(_ container: WebPageHostUIView, context: Context) {
            guard let webView = model.webView() else { return }
            // Re-claim the web view in case another (now dismantled) host held it
            container.host(webView)
            model.sessionController.update(webView: webView, model: model)
        }
    }
}

@MainActor
final class WebPageHostUIView: UIView {
    func host(_ webView: WKWebView) {
        guard webView.superview !== self else { return }
        webView.removeFromSuperview()
        webView.frame = bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(webView)
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
    let client = MockBluetoothClient()
    let bluetoothEngine = BluetoothEngine(
        eventBus: EventBus(),
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
        navigator: WebNavigator(),
        virtualKeyboardModel: .init()
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
