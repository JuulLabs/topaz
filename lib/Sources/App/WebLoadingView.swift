import BluetoothClient
import DevicePicker
import Observation
import SwiftUI
import WebView
import WebKit

struct WebLoadingView: View {
    @State private var webConfig: WKWebViewConfiguration?

    let loader: WebConfigLoader
    let model: WebContainerModel

    var body: some View {
        ZStack {
            if let webConfig {
                WebContainerView(model: model, config: webConfig)
            }
            if webConfig == nil || model.webPageModel.isPerformingInitialContentLoad {
                FullscreenLoadingView()
                    .task {
                        await loadConfigAsync()
                    }
            }
        }
    }

    private func loadConfigAsync() async {
        do {
            let loaded = try await loader.loadConfig()
            withAnimation(.easeInOut(duration: 0.25)) {
                webConfig = loaded
            }
        } catch {
            // TODO: navigate away due to failure and try again
            print("Unable to load \(error)")
        }
    }
}

#Preview("Ok") {
    WebLoadingView(
        loader: WebConfigLoader(),
        model: previewModel()
    )
}

#Preview("BadScript") {
    WebLoadingView(
        loader: WebConfigLoader(scriptResourceNames: ["LostFile"]),
        model: previewModel()
    )
}

@MainActor
private func previewModel() -> WebContainerModel {
    WebContainerModel(
        webPageModel: WebPageModel(
            tab: 0,
            url: URL(string: "https://cataas.com/cat")!,
            messageProcessors: []
        ),
        selector: DeviceSelector()
    )
}
