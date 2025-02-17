import DevicePicker
import Observation
import SwiftUI
import WebView

@MainActor
@Observable
public final class WebContainerModel {
    public let webPageModel: WebPageModel
    public let pickerModel: DevicePickerModel
    public var navBarModel: NavBarModel
    public var selector: DeviceSelector

    init(
        webPageModel: WebPageModel,
        navBarModel: NavBarModel,
        selector: DeviceSelector
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
    }
}
