import Bluetooth
@testable import BluetoothAction
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import Foundation
import JsMessage
import Testing

@Suite(.timeLimit(.minutes(1)))
struct DiscoverCharacteristicsTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    private let context = JsContext(
        id: JsContextIdentifier(tab: 0, url: URL(string: "https://topaz.com/")!),
        eventSink: { _ in .success(()) }
    )

    @Test
    func discoverCharacteristics_single_withCharacteristic() async throws {
        let fakeService = FakeService(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!)
        let fake = FakePeripheral(id: zeroUuid, connectionState: .connected, services: [fakeService])
        let expectedCharacteristics = [
            FakeCharacteristic(uuid: UUID(uuidString: "00000003-0001-0000-0000-000000000000")!),
        ]
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(true),
                "device": .string(fake.id.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "characteristic": .string("00000003-0001-0000-0000-000000000000"),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onDiscoverCharacteristics = { peripheral, filter in
                CharacteristicDiscoveryEvent(peripheralId: peripheral.id, serviceId: filter.service, characteristics: expectedCharacteristics)
            }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake)
        }
        await sut.didAttach(to: context)
        let message = Message(action: .discoverCharacteristics, requestBody: requestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? DiscoverCharacteristicsResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.characteristics == expectedCharacteristics)
    }

    @Test
    func discoverCharacteristics_withoutCharacteristic() async throws {
        let fakeServices: [Service] = [
            FakeService(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!),
            FakeService(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!),
        ]
        let fake = FakePeripheral(id: zeroUuid, connectionState: .connected, services: fakeServices)
        let expectedCharacteristics = [
            FakeCharacteristic(uuid: UUID(uuidString: "00000003-0001-0000-0000-000000000000")!),
            FakeCharacteristic(uuid: UUID(uuidString: "00000003-0002-0000-0000-000000000000")!),
        ]
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(false),
                "device": .string(fake.id.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onDiscoverCharacteristics = { peripheral, filter in
                CharacteristicDiscoveryEvent(peripheralId: peripheral.id, serviceId: filter.service, characteristics: expectedCharacteristics)
            }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake)
        }
        await sut.didAttach(to: context)
        let message = Message(action: .discoverCharacteristics, requestBody: requestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? DiscoverCharacteristicsResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.characteristics == expectedCharacteristics)
    }

    @Test
    func discoverCharacteristics_withCharacteristic() async throws {
        let expectedCharacteristics = [
            FakeCharacteristic(uuid: UUID(uuidString: "00000003-0001-0000-0000-000000000000")!),
        ]
        let fakeServices: [Service] = [
            FakeService(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!),
            FakeService(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!),
        ]
        let fake = FakePeripheral(id: zeroUuid, connectionState: .connected, services: fakeServices)
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(false),
                "device": .string(fake.id.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "characteristic": .string("00000003-0001-0000-0000-000000000000"),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onDiscoverCharacteristics = { peripheral, filter in
                _ = try #require(fakeServices.first(where: { $0.uuid == filter.service }))
                return CharacteristicDiscoveryEvent(peripheralId: peripheral.id, serviceId: filter.service, characteristics: expectedCharacteristics)
            }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake)
        }
        await sut.didAttach(to: context)
        let message = Message(action: .discoverCharacteristics, requestBody: requestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? DiscoverCharacteristicsResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.characteristics == expectedCharacteristics)
    }
}
