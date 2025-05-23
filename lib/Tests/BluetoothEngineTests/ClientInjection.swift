import Bluetooth
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import DevicePicker
import EventBus

func withClient(
    eventBus: EventBus,
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
    return BluetoothEngine(eventBus: eventBus, state: state, client: client, deviceSelector: selector)
}

func poweredOnMockClient(eventBus: EventBus) -> MockBluetoothClient {
    var client = MockBluetoothClient()
    client.onEnable = {
        eventBus.enqueueEvent(SystemStateEvent(.poweredOn))
    }
    return client
}
