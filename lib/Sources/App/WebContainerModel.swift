import DevicePicker
import Observation
import SwiftUI
import WebView

@MainActor
@Observable
public class WebContainerModel {
    public let webPageModel: WebPageModel
    public let pickerModel: DevicePickerModel
    public var selector: DeviceSelector

    public init(
        webPageModel: WebPageModel,
        selector: DeviceSelector
    ) {
        self.webPageModel = webPageModel
        self.selector = selector
        self.pickerModel = DevicePickerModel(
            siteName: webPageModel.hostname,
            selector: selector,
            onDismiss: {
                selector.cancel()
            }
        )
    }
}
