import Bluetooth
@testable import BluetoothAction
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
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
        let sut = await withClient { _, client, _ in
            client.onEnable = { }
            client.onSystemState = { SystemStateEvent(state) }
        }
        let response = try await sut.processAction(message: Message(action: .getAvailability))
        guard let response = response as? AvailabilityResponse else {
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
        let sut = await withClient { _, client, _ in
            client.onEnable = { }
            client.onSystemState = { SystemStateEvent(state) }
        }
        let response = try await sut.processAction(message: Message(action: .getAvailability))
        guard let response = response as? AvailabilityResponse else {
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
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onConnect = { PeripheralEvent(.connect, $0) }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake.eraseToAnyPeripheral())
        }
        await sut.didAttach(to: context)
        let message = Message(action: .connect, requestBody: connectRequestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? ConnectResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isConnected == true)
    }

    @Test
    func disconnect() async throws {
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .connected)
        let disconnectRequestBody: [String: JsType] = [
            "data": .dictionary([
                "uuid": .string(fake._identifier.uuidString),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onDisconnect = { PeripheralEvent(.disconnect, $0) }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake.eraseToAnyPeripheral())
        }
        await sut.didAttach(to: context)
        let message = Message(action: .disconnect, requestBody: disconnectRequestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? DisconnectResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isDisconnected == true)
    }

    @Test
    func discoverServices_single_withService() async throws {
        let expectedServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true)
        ]
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .connected, services: expectedServices)
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "device": .string(fake._identifier.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "single": .number(true),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onDiscoverServices = { peripheral, _ in PeripheralEvent(.discoverServices, peripheral) }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake.eraseToAnyPeripheral())
        }
        await sut.didAttach(to: context)
        let message = Message(action: .discoverServices, requestBody: requestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? DiscoverServicesResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.services == expectedServices)
    }

    @Test
    func discoverServices_withoutService() async throws {
        let expectedServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!, isPrimary: true),
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true),
        ]
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .connected, services: expectedServices)
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "device": .string(fake._identifier.uuidString),
                "single": .number(false),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onDiscoverServices = { peripheral, _ in PeripheralEvent(.discoverServices, peripheral) }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake.eraseToAnyPeripheral())
        }
        await sut.didAttach(to: context)
        let message = Message(action: .discoverServices, requestBody: requestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? DiscoverServicesResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.services == expectedServices)
    }

    @Test
    func discoverServices_withService() async throws {
        let expectedServices: [Service] = [
            Service(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true)
        ]
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid, connectionState: .connected, services: expectedServices)
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "device": .string(fake._identifier.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "single": .number(false),
            ]),
        ]
        let sut: BluetoothEngine = await withClient { state, client, _ in
            client.onEnable = { }
            client.onDiscoverServices = { peripheral, _ in PeripheralEvent(.discoverServices, peripheral) }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake.eraseToAnyPeripheral())
        }
        await sut.didAttach(to: context)
        let message = Message(action: .discoverServices, requestBody: requestBody)
        let response = try await sut.processAction(message: message)
        guard let response = response as? DiscoverServicesResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.services == expectedServices)
    }
}
