import Bluetooth
import BluetoothEngine
import DevicePicker
import Observation
import SwiftUI
import VirtualKeyboard
import WebView

@MainActor
@Observable
public final class WebContainerModel {
    public var webPageModel: WebPageModel
    public let pickerModel: DevicePickerModel
    public var navBarModel: NavBarModel
    public var selector: DeviceSelector
    public let virtualKeyboard: VirtualKeyboardModel

    var bluetoothSystem: BluetoothSystemState
    var shouldShowErrorState: Bool {
        bluetoothSystem.systemState != .unknown && bluetoothSystem.systemState != .poweredOn
    }

    init(
        webPageModel: WebPageModel,
        navBarModel: NavBarModel,
        selector: DeviceSelector,
        virtualKeyboard: VirtualKeyboardModel = .shared,
        bluetoothSystem: BluetoothSystemState = .shared
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
        self.virtualKeyboard = virtualKeyboard
        self.bluetoothSystem = bluetoothSystem
    }
}
