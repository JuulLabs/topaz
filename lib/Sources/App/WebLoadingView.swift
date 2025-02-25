import Bluetooth
import BluetoothClient
import DevicePicker
import JsMessage
import Observation
import SwiftUI
import WebView
import WebKit

struct WebLoadingView: View {
    let model: WebLoadingModel

    var body: some View {
        ZStack {
            if let webContainerModel = model.webContainerModel {
                WebContainerView(webContainerModel: webContainerModel)
            }
            if model.shouldShowFreshPageOverlay {
                FreshPageView(model: model.freshPageModel)
            }
        }
        .id(model.id)
        .animation(.easeInOut, value: model.shouldShowFreshPageOverlay)
    }
}

#Preview("Empty") {
    WebLoadingView(
        model: previewModel()
    )
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Loading") {
    let model: WebLoadingModel = previewModel()
    WebLoadingView(
        model: model
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
        model: model
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
    let navBarModel = NavBarModel() { _ in }
    let freshPageModel = FreshPageModel(searchBarModel: navBarModel.searchBarModel)
    return WebLoadingModel(
        freshPageModel: freshPageModel,
        navBarModel: navBarModel
    )
}

@MainActor
private func webModel(url: URL) -> WebContainerModel {
    let navBarModel = NavBarModel() { _ in }
    return WebContainerModel(
        webPageModel: WebPageModel(
            tab: 0,
            url: url,
            config: previewWebConfig(),
            messageProcessorFactory: staticMessageProcessorFactory(),
            navigator: navBarModel.navigator
        ),
        navBarModel: navBarModel,
        selector: DeviceSelector()
    )
}
