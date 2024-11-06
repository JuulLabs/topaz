import DevicePicker
import Observation
import SwiftUI
import WebView
import WebKit

@MainActor
@Observable
public final class WebContainerModel {
    public let webPageModel: WebPageModel
    public let pickerModel: DevicePickerModel
    public var selector: DeviceSelector

    init(
        webPageModel: WebPageModel,
        selector: DeviceSelector
    ) {
        self.webPageModel = webPageModel
        self.selector = selector
        self.pickerModel = DevicePickerModel(
            siteName: webPageModel.hostname,
            selector: selector,
            onDismiss: { [selector] in
                selector.cancel()
            }
        )
    }

    static func loadAsync(
        selector: DeviceSelector,
        webConfigLoader: WebConfigLoader,
        buildWebModel: @escaping (WKWebViewConfiguration) -> WebPageModel
    ) async throws -> WebContainerModel {
        let config = try await webConfigLoader.loadConfig()
        let webPageModel = buildWebModel(config)
        return .init(webPageModel: webPageModel, selector: selector)
    }
}
