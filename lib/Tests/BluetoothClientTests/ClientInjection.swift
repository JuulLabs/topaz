import Bluetooth
@testable import BluetoothClient
import DevicePicker

func withClient(
    modify: (_ request: inout RequestClient, _ response: inout ResponseClient, _ selector: inout any InteractiveDeviceSelector) async -> Void
) async -> BluetoothEngine {
    var request = RequestClient.testValue
    var response = ResponseClient.testValue
    var selector: InteractiveDeviceSelector = await TestDeviceSelector()
    await modify(&request, &response, &selector)
    let client = BluetoothClient(request: request, response: response)
    return BluetoothEngine(deviceSelector: selector, client: client)
}
