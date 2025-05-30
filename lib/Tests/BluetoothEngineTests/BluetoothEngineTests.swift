import Bluetooth
@testable import BluetoothAction
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import Testing

@Suite(.timeLimit(.minutes(1)))
struct BluetoothEngineTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    private let url: URL! = URL(string: "https://topaz.com/")
    private let context = JsContext(
        id: JsContextIdentifier(tab: 0, url: URL(string: "https://topaz.com/")!),
        eventSink: { _ in .success(()) }
    )
    private let eventBus = EventBus()

    private let fakeServices: [Service] = [
        FakeService(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!, isPrimary: true),
        FakeService(uuid: UUID(uuidString: "00000002-0000-0000-0000-000000000000")!, isPrimary: false),
        FakeService(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true),
    ]

    @Test(arguments: [
        SystemState.resetting,
        SystemState.poweredOn,
    ])
    func process_getAvailability_returnsTrue(state: SystemState) async throws {
        let sut = await withClient(eventBus: eventBus) { _, _, _ in }
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!), eventSink: { _ in .success(()) })
        await sut.didAttach(to: context)
        eventBus.enqueueEvent(SystemStateEvent(state))
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
        let sut = await withClient(eventBus: eventBus) { _, _, _ in }
        let context = JsContext(id: .init(tab: 0, url: URL(string: "http://test.com")!), eventSink: { _ in .success(()) })
        await sut.didAttach(to: context)
        eventBus.enqueueEvent(SystemStateEvent(state))
        let response = try await sut.processAction(message: Message(action: .getAvailability))
        guard let response = response as? AvailabilityResponse else {
            Issue.record("Unexpected response: \(response)")
            return
        }
        #expect(response.isAvailable == false)
    }

    @Test
    func connect() async throws {
        let fake = FakePeripheral(id: zeroUuid)
        let connectRequestBody: [String: JsType] = [
            "data": .dictionary([
                "uuid": .string(fake.id.uuidString),
            ]),
        ]
        let sut: BluetoothEngine = await withClient(eventBus: eventBus) { state, client, _ in
            client.onEnable = { }
            client.onConnect = { eventBus.enqueueEvent(PeripheralEvent(.connect, $0)) }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake, replace: true)
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
        let fake = FakePeripheral(id: zeroUuid, connectionState: .connected)
        let disconnectRequestBody: [String: JsType] = [
            "data": .dictionary([
                "uuid": .string(fake.id.uuidString),
            ]),
        ]
        let sut: BluetoothEngine = await withClient(eventBus: eventBus) { state, client, _ in
            client.onEnable = { }
            client.onDisconnect = { eventBus.enqueueEvent(DisconnectionEvent.requested($0)) }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake, replace: true)
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
        let fake = FakePeripheral(id: zeroUuid, connectionState: .connected)
        let expectedServices: [Service] = [
            FakeService(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true)
        ]
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "device": .string(fake.id.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "single": .number(true),
            ]),
        ]
        let sut: BluetoothEngine = await withClient(eventBus: eventBus) { state, client, _ in
            client.onEnable = { }
            client.onDiscoverServices = { peripheral, _ in
                eventBus.enqueueEvent(ServiceDiscoveryEvent(peripheralId: peripheral.id, services: expectedServices))
            }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake, replace: true)
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
        let fake = FakePeripheral(id: zeroUuid, connectionState: .connected)
        let expectedServices: [Service] = [
            FakeService(uuid: UUID(uuidString: "00000001-0000-0000-0000-000000000000")!, isPrimary: true),
            FakeService(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true),
        ]
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "device": .string(fake.id.uuidString),
                "single": .number(false),
            ]),
        ]
        let sut: BluetoothEngine = await withClient(eventBus: eventBus) { state, client, _ in
            client.onEnable = { }
            client.onDiscoverServices = { peripheral, _ in
                eventBus.enqueueEvent(ServiceDiscoveryEvent(peripheralId: peripheral.id, services: expectedServices))
            }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake, replace: true)
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
        let fake = FakePeripheral(id: zeroUuid, connectionState: .connected)
        let expectedServices: [Service] = [
            FakeService(uuid: UUID(uuidString: "00000003-0000-0000-0000-000000000000")!, isPrimary: true)
        ]
        let requestBody: [String: JsType] = [
            "data": .dictionary([
                "device": .string(fake.id.uuidString),
                "service": .string("00000003-0000-0000-0000-000000000000"),
                "single": .number(false),
            ]),
        ]
        let sut: BluetoothEngine = await withClient(eventBus: eventBus) { state, client, _ in
            client.onEnable = { }
            client.onDiscoverServices = { peripheral, _ in
                eventBus.enqueueEvent(ServiceDiscoveryEvent(peripheralId: peripheral.id, services: expectedServices))
            }
            await state.setSystemState(.poweredOn)
            await state.putPeripheral(fake, replace: true)
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
