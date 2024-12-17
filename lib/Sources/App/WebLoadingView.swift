import Bluetooth
import BluetoothClient
import DevicePicker
import Observation
import SwiftUI
import WebView
import WebKit

struct WebLoadingView: View {
    let model: WebLoadingModel
    let searchBarModel: SearchBarModel

    var body: some View {
        ZStack {
            if let webContainerModel = model.webContainerModel {
                WebContainerView(
                    webContainerModel: webContainerModel,
                    searchBarModel: searchBarModel
                )
            }
            if model.shouldShowFreshPageOverlay {
                FreshPageView(model: model.freshPageModel)
            }
        }
        .animation(.easeInOut, value: model.shouldShowFreshPageOverlay)
    }
}

#Preview("Empty") {
    WebLoadingView(
        model: previewModel(),
        searchBarModel: SearchBarModel()
    )
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Loading") {
    let model: WebLoadingModel = previewModel()
    WebLoadingView(
        model: model,
        searchBarModel: SearchBarModel()
    )
    .task {
        model.freshPageModel.isLoading = true
    }
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Loaded") {
    let model: WebLoadingModel = previewModel()
    WebLoadingView(
        model: model,
        searchBarModel: SearchBarModel()
    )
    .task {
        model.freshPageModel.isLoading = true
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
        let url = URL.init(string: "https://loremipsum.org")!
        model.webContainerModel = webModel(url: url)
    }
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

@MainActor
private func previewModel() -> WebLoadingModel {
    let freshPageModel = FreshPageModel(searchBarModel: SearchBarModel())
    return WebLoadingModel(freshPageModel: freshPageModel)
}

@MainActor
private func webModel(url: URL) -> WebContainerModel {
    WebContainerModel(
        webPageModel: WebPageModel(
            tab: 0,
            url: url,
            config: previewWebConfig(),
            messageProcessors: []
        ),
        navBarModel: NavBarModel(),
        selector: DeviceSelector(),
        bluetoothStateStream: AsyncStream<SystemState>.makeStream().stream
    )
}
