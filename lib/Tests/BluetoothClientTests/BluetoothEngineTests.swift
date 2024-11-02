import Bluetooth
@testable import BluetoothClient
import Foundation
import JsMessage
import Testing

@Suite(.timeLimit(.minutes(1)))
struct BluetoothEngineTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    private let url: URL! = URL(string: "https://topaz.com/")
    private let context = JsContext(
        id: JsContextIdentifier(tab: 0, url: URL(string: "https://topaz.com/")!),
        eventSink: { _ in }
    )

    private let fakeServices: [Service] = [
        Service(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!, isPrimary: true),
        Service(uuid: UUID(uuidString: "00000002-0000-0000-0000-000000000000")!, isPrimary: false),
        Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true),
    ]

    @Test(arguments: [
        SystemState.resetting,
        SystemState.poweredOn,
    ])
    func process_getAvailability_returnsTrue(state: SystemState) async throws {
        let sut = await withClient { request, response, _ in
            request.enable = { }
            response.events = AsyncStream { continuation in
                continuation.yield(.systemState(state))
            }
        }
        let response = try await sut.process(message: Message(action: .getAvailability))
        guard let response = response as? GetAvailabilityResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isAvailable == true)
    }

    @Test(arguments: [
        // SystemState.unknown, - excluded because we block until != unknown
        SystemState.unsupported,
        SystemState.unauthorized,
        SystemState.poweredOff,
    ])
    func process_getAvailability_returnsFalse(state: SystemState) async throws {
        let sut = await withClient { request, response, _ in
            request.enable = { }
            response.events = AsyncStream { continuation in
                continuation.yield(.systemState(state))
            }
        }
        let response = try await sut.process(message: Message(action: .getAvailability))
        guard let response = response as? GetAvailabilityResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isAvailable == false)
    }

    @Test
    func connect() async throws {
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid)
        let connectRequestBody: [String: JsType] = [
            "data": .dictionary([
                "uuid": .string(fake._identifier.uuidString),
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
            request.connect = { [events] peripheral in
                events!.yield(.connected(peripheral))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .connect, requestBody: connectRequestBody)
        let response = try await sut.process(message: message)
        guard let response = response as? ConnectResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isConnected == true)
    }

    @Test
    func disconnect() async throws {
        let fake = FakePeripheral(name: "bob", connectionState: .connected, identifier: zeroUuid)
        let disconnectRequestBody: [String: JsType] = [
            "data": .dictionary([
                "uuid": .string(fake._identifier.uuidString),
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
            request.disconnect = { [events] peripheral in
                events!.yield(.disconnected(peripheral, nil))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .disconnect, requestBody: disconnectRequestBody)
        let response = try await sut.process(message: message)
        guard let response = response as? DisconnectResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isDisconnected == true)
    }

    @Test
    func getGattChildren_single_withBluetoothServiceUUID() async throws {
        let expectedServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true)
        ]
        let fake = FakePeripheral(name: "bob", connectionState: .connected, identifier: zeroUuid, services: expectedServices)
        let getGattChildrenBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(true),
                "uuid": .string(fake._identifier.uuidString),
                "bluetoothServiceUUID": .string("00000003-0000-0000-0000-000000000000"),
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
            request.discoverServices = { [events] peripheral, _ in
                events!.yield(.discoveredServices(peripheral, nil))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .discoverServices, requestBody: getGattChildrenBody)
        let response = try await sut.process(message: message)
        guard let response = response as? GetGattChildrenResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.services == expectedServices)
    }

    @Test
    func getGattChildren_withoutBluetoothServiceUUID() async throws {
        let expectedServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!, isPrimary: true),
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true),
        ]
        let fake = FakePeripheral(name: "bob", connectionState: .connected, identifier: zeroUuid, services: expectedServices)
        let getGattChildrenBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(false),
                "uuid": .string(fake._identifier.uuidString),
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
            request.discoverServices = { [events] peripheral, _ in
                events!.yield(.discoveredServices(peripheral, nil))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .discoverServices, requestBody: getGattChildrenBody)
        let response = try await sut.process(message: message)
        guard let response = response as? GetGattChildrenResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.services == expectedServices)
    }

    @Test
    func getGattChildren_withBluetoothServiceUUID() async throws {
        let expectedServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true)
        ]
        let fake = FakePeripheral(name: "bob", connectionState: .connected, identifier: zeroUuid, services: expectedServices)
        let getGattChildrenBody: [String: JsType] = [
            "data": .dictionary([
                "single": .number(false),
                "uuid": .string(fake._identifier.uuidString),
                "bluetoothServiceUUID": .string("00000003-0000-0000-0000-000000000000"),
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
            request.discoverServices = { [events] peripheral, _ in
                events!.yield(.discoveredServices(peripheral, nil))
            }
        }
        await sut.addPeripheral(fake.eraseToAnyPeripheral())
        await sut.didAttach(to: context)
        let message = Message(action: .discoverServices, requestBody: getGattChildrenBody)
        let response = try await sut.process(message: message)
        guard let response = response as? GetGattChildrenResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.services == expectedServices)
    }
}
