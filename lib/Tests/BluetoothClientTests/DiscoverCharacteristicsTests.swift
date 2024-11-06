import Bluetooth
@testable import BluetoothClient
import Foundation
import JsMessage
import Testing

@Suite(.timeLimit(.minutes(1)))
struct DiscoverCharacteristicsTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    private let context = JsContext(
        id: JsContextIdentifier(tab: 0, url: URL(string: "https://topaz.com/")!),
        eventSink: { _ in }
    )

    @Test
    func discoverCharacteristics_single_withCharacteristic() async throws {
        let expectedCharacteristics = [
            Characteristic(uuid: UUID(uuidString: "00000003-0001-0000-0000-000000000000")!, properties: CharacteristicProperties(), value: nil, descriptors: [], isNotifying: false),
        ]
        let fakeServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true, characteristics: expectedCharacteristics),
        ]
        let fake = FakePeripheral(name: "bob", connectionState: .connected, identifier: zeroUuid, services: fakeServices)
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(true),
                "uuid": .string(fake._identifier.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "characteristic": .string("00000003-0001-0000-0000-000000000000"),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { request, response, _ in
            var events: AsyncStream<DelegateEvent>.Continuation!
            response.events = AsyncStream { continuation in
                events = continuation
            }
            request.enable = { [events] in
                events!.yield(.systemState(.poweredOn))
            }
            request.discoverCharacteristics = { [events] peripheral, _ in
                events!.yield(.discoveredCharacteristics(peripheral, fakeServices[0], nil))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .discoverCharacteristics, requestBody: requestBody)
        let response = try await sut.process(message: message)
        guard let response = response as? DiscoverCharacteristicsResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.characteristics == expectedCharacteristics)
    }

    @Test
    func discoverCharacteristics_withoutCharacteristic() async throws {
        let expectedCharacteristics = [
            Characteristic(uuid: UUID(uuidString: "00000003-0001-0000-0000-000000000000")!, properties: CharacteristicProperties(), value: nil, descriptors: [], isNotifying: false),
            Characteristic(uuid: UUID(uuidString: "00000003-0002-0000-0000-000000000000")!, properties: CharacteristicProperties(), value: nil, descriptors: [], isNotifying: false),
        ]
        let fakeServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!, isPrimary: true, characteristics: expectedCharacteristics),
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true),
        ]
        let fake = FakePeripheral(name: "bob", connectionState: .connected, identifier: zeroUuid, services: fakeServices)
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(false),
                "uuid": .string(fake._identifier.uuidString),
                "service": .string("00000001-0000-0000-0000-000000000000"),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { request, response, _ in
            var events: AsyncStream<DelegateEvent>.Continuation!
            response.events = AsyncStream { continuation in
                events = continuation
            }
            request.enable = { [events] in
                events!.yield(.systemState(.poweredOn))
            }
            request.discoverCharacteristics = { [events] peripheral, _ in
                events!.yield(.discoveredCharacteristics(peripheral, fakeServices[0], nil))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .discoverCharacteristics, requestBody: requestBody)
        let response = try await sut.process(message: message)
        guard let response = response as? DiscoverCharacteristicsResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.characteristics == expectedCharacteristics)
    }

    @Test
    func discoverCharacteristics_withCharacteristic() async throws {
        let expectedCharacteristics = [
            Characteristic(uuid: UUID(uuidString: "00000003-0001-0000-0000-000000000000")!, properties: CharacteristicProperties(), value: nil, descriptors: [], isNotifying: false),
            Characteristic(uuid: UUID(uuidString: "00000003-0002-0000-0000-000000000000")!, properties: CharacteristicProperties(), value: nil, descriptors: [], isNotifying: false),
        ]
        let fakeServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!, isPrimary: true),
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true, characteristics: expectedCharacteristics),
        ]
        let fake = FakePeripheral(name: "bob", connectionState: .connected, identifier: zeroUuid, services: fakeServices)
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(false),
                "uuid": .string(fake._identifier.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "characteristic": .string("00000003-0001-0000-0000-000000000000"),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { request, response, _ in
            var events: AsyncStream<DelegateEvent>.Continuation!
            response.events = AsyncStream { continuation in
                events = continuation
            }
            request.enable = { [events] in
                events!.yield(.systemState(.poweredOn))
            }
            request.discoverCharacteristics = { [events] peripheral, _ in
                events!.yield(.discoveredCharacteristics(peripheral, fakeServices[0], nil))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .discoverCharacteristics, requestBody: requestBody)
        let response = try await sut.process(message: message)
        guard let response = response as? DiscoverCharacteristicsResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.characteristics == expectedCharacteristics)
    }
}
