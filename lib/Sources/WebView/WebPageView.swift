import BluetoothClient
import BluetoothEngine
import BluetoothMessage
import DevicePicker
import EventBus
import JsMessage
import Navigation
import SwiftUI
import WebKit

public struct WebPageView: View {
    @State private var scrollView: UIScrollView?

    @Bindable var model: WebPageModel

    public init(model: WebPageModel) {
        self.model = model
    }

    public var body: some View {
        _WebPageView(model: model, scrollView: $scrollView)
            .id(model.id)
            .preference(key: WebPageScrollViewKey.self, value: scrollView)
            .alert("This website would like to use Bluetooth®", isPresented: $model.presentPermissionsDialog, actions: {
                Button {
                    model.allowPermissionsButtonTapped()
                } label: {
                    Text("Allow")
                }
                Button(role: .cancel) {
                    model.denyPermissionsButtonTapped()
                } label: {
                    Text("Deny")
                }
            }, message: {
                Text(model.permissionsDialogMessage)
            })
    }

    private struct _WebPageView: UIViewRepresentable {
        @Binding private var scrollView: UIScrollView?

        private let model: WebPageModel

        init (model: WebPageModel, scrollView: Binding<UIScrollView?>) {
            self.model = model
            self._scrollView = scrollView
        }

        func makeUIView(context: Context) -> WKWebView {
            let webView = model.webView()
            // Defensive: a model-owned web view could still be parented elsewhere
            webView.removeFromSuperview()
            context.coordinator.model = model
            Task { @MainActor in
                scrollView = webView.scrollView
            }
            return webView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            model.sessionController.update(webView: uiView, model: model)
        }

        static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
            // The session (web view, script handler, BLE) is owned by the model; leaving
            // the view still ends the session for now to preserve existing behavior.
            coordinator.model?.teardown()
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        @MainActor
        final class Coordinator {
            weak var model: WebPageModel?
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
