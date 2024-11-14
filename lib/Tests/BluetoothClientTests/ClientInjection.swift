import Bluetooth
@testable import BluetoothClient
import DevicePicker

func withClient(
    modify: (_ state: BluetoothState, _ request: inout RequestClient, _ response: inout ResponseClient, _ selector: inout any InteractiveDeviceSelector) async -> Void
) async -> BluetoothEngine {
    let state = BluetoothState()
    var request = RequestClient.testValue
    var response = ResponseClient.testValue
    var selector: InteractiveDeviceSelector = await TestDeviceSelector()
    await modify(state, &request, &response, &selector)
    let client = BluetoothClient(request: request, response: response)
    return BluetoothEngine(state: state, deviceSelector: selector, client: client)
}
