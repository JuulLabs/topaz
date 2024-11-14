import Bluetooth
import BluetoothClient
@testable import BluetoothEngine
import DevicePicker
import Effector

func withClient(
    modify: (
        _ state: BluetoothState,
        _ effector: inout Effector,
        _ request: inout RequestClient,
        _ response: inout ResponseClient,
        _ selector: inout any InteractiveDeviceSelector
    ) async -> Void
) async -> BluetoothEngine {
    let state = BluetoothState()
    var effector = Effector.testValue
    var request = RequestClient.testValue
    var response = ResponseClient.testValue
    var selector: InteractiveDeviceSelector = await TestDeviceSelector()
    await modify(state, &effector, &request, &response, &selector)
    let client = BluetoothClient(request: request, response: response)
    return BluetoothEngine(state: state, effector: effector, deviceSelector: selector, client: client)
}
