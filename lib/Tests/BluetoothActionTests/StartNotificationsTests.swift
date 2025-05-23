import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import SecurityList
import TestHelpers
import Testing
import XCTest

extension Tag {
    @Tag static var startNotifications: Self
}

private let fakePeripheralId = UUID(n: 0)
private let fakeServiceUuid = UUID(n: 1)
private let fakeCharacteristicUuid = UUID(n: 2)
private let fakeCharacteristicInstance: UInt32 = 3
private let characteristicNotifyEvent = CharacteristicEvent(
    .characteristicNotify,
    peripheralId: fakePeripheralId,
    serviceId: fakeServiceUuid,
    characteristicId: fakeCharacteristicUuid,
    instance: fakeCharacteristicInstance
)

@Suite(.tags(.startNotifications))
struct StartNotificationsTests {
    @Test
    func execute_withBasicPeripheral_clientShouldStartNotifications() async throws {
        let eventBus = await selfResolvingEventBus()
        let startInvokedExpectation = XCTestExpectation(description: "onStartNotifications invoked")
        var client = MockBluetoothClient()
        client.onCharacteristicSetNotifications = { _, _, startNotifying in
            if startNotifying {
                startInvokedExpectation.fulfill()
            }
            eventBus.enqueueEvent(characteristicNotifyEvent)
        }
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify, .indicate])])
        let sut = StartNotifications(request: request())

        _ = try await sut.execute(state: state, client: client, eventBus: eventBus)

        let outcome = await XCTWaiter().fulfillment(of: [startInvokedExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }

    @Test
    func execute_withNotifiableCharacteristic_noErrorIsThrown() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify, .indicate])])
        let sut = StartNotifications(request: request())

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    @Test
    func execute_withDisconnectedPeripheral_throwsDeviceNotConnectedError() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let state = BluetoothState(peripherals: [fakePeripheral(.disconnected, properties: [.notify, .indicate])])
        let sut = StartNotifications(request: request())

        await #expect(throws: BluetoothError.deviceNotConnected) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    @Test
    func execute_characteristicNotFound_throwsNoSuchCharacteristicError() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let nonExistentCharacteristicUuid = UUID(n: 7351)
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify, .indicate])])
        let sut = StartNotifications(request: request(characteristicUuid: nonExistentCharacteristicUuid))

        await #expect(throws: BluetoothError.noSuchCharacteristic(service: fakeServiceUuid, characteristic: nonExistentCharacteristicUuid)) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    @Test
    func execute_characteristicHasNeitherNotifyNorIndicateSet_throwsCharacteristicNotificationsNotSupportedError() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [])])
        let sut = StartNotifications(request: request())

        await #expect(throws: BluetoothError.characteristicNotificationsNotSupported(characteristic: fakeCharacteristicUuid)) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    @Test
    func execute_characteristicHasNotifySet_noErrorIsThrown() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify])])
        let sut = StartNotifications(request: request())

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    @Test
    func execute_characteristicHasIndicateSet_noErrorIsThrown() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.indicate])])
        let sut = StartNotifications(request: request())

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    @Test
    func execute_characteristicIsAlreadyNotifying_clientShouldNotStartNotifications() async throws {
        let eventBus = await selfResolvingEventBus()
        let startInvokedExpectation = XCTestExpectation(description: "onStartNotifications invoked")
        startInvokedExpectation.isInverted = true
        var client = MockBluetoothClient()
        client.onCharacteristicSetNotifications = { _, _, startNotifying in
            if startNotifying {
                startInvokedExpectation.fulfill()
            }
            eventBus.enqueueEvent(characteristicNotifyEvent)
        }
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify, .indicate], isNotifying: true)])
        let sut = StartNotifications(request: request())
        _ = try await sut.execute(state: state, client: client, eventBus: eventBus)

        let outcome = await XCTWaiter().fulfillment(of: [startInvokedExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }

    @Test
    func execute_withCharacteristicBlockedForReading_throwsBlocklistedError() async throws {
        let securityList = SecurityList(characteristics: [fakeCharacteristicUuid: .reading])
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify])], securityList: securityList)
        let sut = StartNotifications(request: request())
        await #expect(throws: BluetoothError.blocklisted(fakeCharacteristicUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    @Test
    func execute_withCharacteristicBlockedForWriting_doesNotThrow() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let securityList = SecurityList(characteristics: [fakeCharacteristicUuid: .writing])
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify])], securityList: securityList)
        let sut = StartNotifications(request: request())
        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    private func request(characteristicUuid: UUID = fakeCharacteristicUuid) -> CharacteristicRequest {
        CharacteristicRequest(
            peripheralId: fakePeripheralId,
            serviceUuid: fakeServiceUuid,
            characteristicUuid: characteristicUuid,
            characteristicInstance: fakeCharacteristicInstance
        )
    }

    private func fakePeripheral(_ connectionState: ConnectionState, properties: CharacteristicProperties, isNotifying: Bool = false) -> Peripheral {
        let characteristic = FakeCharacteristic(
            uuid: fakeCharacteristicUuid,
            instance: fakeCharacteristicInstance,
            properties: properties,
            isNotifying: isNotifying
        )
        return FakePeripheral(
            id: fakePeripheralId,
            connectionState: connectionState,
            services: [FakeService(uuid: fakeServiceUuid, characteristics: [characteristic])]
        )
    }

    private func clientThatSucceeds(eventBus: EventBus) -> BluetoothClient {
        var client = MockBluetoothClient()
        client.onCharacteristicSetNotifications = { [eventBus] _, _, _ in
            eventBus.enqueueEvent(characteristicNotifyEvent)
        }
        return client
    }
}
