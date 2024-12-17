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

    private let bluetoothStateStream: AsyncStream<SystemState>

    init(
        webPageModel: WebPageModel,
        navBarModel: NavBarModel,
        selector: DeviceSelector,
        bluetoothStateStream: AsyncStream<SystemState>
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
        self.bluetoothStateStream = bluetoothStateStream
    }

    static func loadAsync(
        selector: DeviceSelector,
        webConfigLoader: WebConfigLoader,
        bluetoothStateStream: AsyncStream<SystemState>,
        buildWebModel: @escaping (WKWebViewConfiguration) -> WebPageModel
    ) async throws -> WebContainerModel {
        let config = try await webConfigLoader.loadConfig()
        let webPageModel = buildWebModel(config)
        let navBarModel = NavBarModel(navigator: webPageModel.navigator, bluetoothStateStream: bluetoothStateStream)
        return .init(webPageModel: webPageModel, navBarModel: navBarModel, selector: selector, bluetoothStateStream: bluetoothStateStream)
    }
}
