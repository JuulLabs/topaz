import Bluetooth
@testable import BluetoothClient
import DevicePicker
import Foundation
import Testing

struct EndToEndBluetoothEngineTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")

    /// Tests the integration of:
    /// 1. web app initiating a promise to request a device
    /// 2. blutooth emitting advertisements for a device
    /// 2. user selecting the device from the picker
    /// 3. engine fulfills the selected device promise
    @Test func process_requestDevice_returnsDeviceWhenSelected() async throws {
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid)
        let selectorSut = await DeviceSelector()
        let engineSut: BluetoothEngine = await withClient { request, response, selector in
            var events: AsyncStream<DelegateEvent>.Continuation!
            response.events = AsyncStream { continuation in
                events = continuation
            }
            request.enable = { [events] in
                events!.yield(.systemState(.poweredOn))
            }
            request.startScanning = { [events] _ in
                events!.yield(.advertisement(fake.eraseToAnyPeripheral(), fake.fakeAd(rssi: 0)))
            }
            request.stopScanning = { }
            selector = selectorSut
        }

        async let promise = await engineSut.process(request: .requestDevice(Filter(services: [])))
        let advertisements = await selectorSut.advertisements.first(where: { !$0.isEmpty })
        await selectorSut.makeSelection(advertisements!.first!.peripheralId)
        let response = await promise
        guard case let .device(deviceId, deviceName) = response else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(advertisements!.count == 1)
        #expect(deviceId == zeroUuid)
        #expect(deviceName == "bob")
    }

}
