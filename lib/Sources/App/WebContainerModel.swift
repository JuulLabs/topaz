import Bluetooth
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
    public var navBarModel: NavBarModel
    public var selector: DeviceSelector

    private let bleStateStream: AsyncStream<SystemState>

    init(
        webPageModel: WebPageModel,
        navBarModel: NavBarModel,
        selector: DeviceSelector,
        bleStateStream: AsyncStream<SystemState>
    ) {
        self.webPageModel = webPageModel
        self.navBarModel = navBarModel
        self.selector = selector
        self.pickerModel = DevicePickerModel(
            siteName: webPageModel.hostname,
            selector: selector,
            onDismiss: { [selector] in
                selector.cancel()
            }
        )
        self.bleStateStream = bleStateStream
    }

    static func loadAsync(
        selector: DeviceSelector,
        webConfigLoader: WebConfigLoader,
        bleStateStream: AsyncStream<SystemState>,
        buildWebModel: @escaping (WKWebViewConfiguration) -> WebPageModel
    ) async throws -> WebContainerModel {
        let config = try await webConfigLoader.loadConfig()
        let webPageModel = buildWebModel(config)
        let navBarModel = NavBarModel(navigator: webPageModel.navigator, bleStateStream: bleStateStream) // pass along async stream from bluetooth engine
        return .init(webPageModel: webPageModel, navBarModel: navBarModel, selector: selector, bleStateStream: bleStateStream)
    }
}
