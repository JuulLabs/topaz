import Bluetooth
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import DevicePicker
import EventBus

func withClient(
    modify: (
        _ state: BluetoothState,
        _ client: inout MockBluetoothClient,
        _ selector: inout InteractiveDeviceSelector
    ) async -> Void
) async -> BluetoothEngine {
    let state = BluetoothState()
    var client = MockBluetoothClient()
    var selector: InteractiveDeviceSelector = await TestDeviceSelector()
    await modify(state, &client, &selector)
    return BluetoothEngine(state: state, client: client, deviceSelector: selector)
}

func poweredOnMockClient() -> MockBluetoothClient {
    var client = MockBluetoothClient()
    client.onEnable = { [events = client.eventsContinuation] in
        events.yield(SystemStateEvent(.poweredOn))
    }
    return client
}
