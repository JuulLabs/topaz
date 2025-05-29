import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import TestHelpers
import Testing
import XCTest

extension Tag {
    @Tag static var stopNotifications: Self
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

@Suite(.tags(.stopNotifications))
struct StopNotificationsTests {
    @Test
    func execute_withBasicPeripheral_clientShouldStopNotifications() async throws {
        let eventBus = await selfResolvingEventBus()
        let stopInvokedExpectation = XCTestExpectation(description: "onStopNotifications invoked")
        var client = MockBluetoothClient()
        client.onCharacteristicSetNotifications = { [eventBus] _, _, startNotifying in
            if startNotifying == false {
                stopInvokedExpectation.fulfill()
            }
            eventBus.enqueueEvent(characteristicNotifyEvent)
        }
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify, .indicate])])
        let sut = StopNotifications(request: request())

        _ = try await sut.execute(state: state, client: client, eventBus: eventBus)

        let outcome = await XCTWaiter().fulfillment(of: [stopInvokedExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }

    @Test
    func execute_withNotifiableCharacteristic_noErrorIsThrown() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify, .indicate])])
        let sut = StopNotifications(request: request())

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
        }
    }

    @Test
    func execute_characteristicNotFound_throwsNoSuchCharacteristicError() async throws {
        let eventBus = await selfResolvingEventBus()
        let client = clientThatSucceeds(eventBus: eventBus)
        let nonExistentCharacteristicUuid = UUID(n: 7351)
        let state = BluetoothState(peripherals: [fakePeripheral(.connected, properties: [.notify])])
        let sut = StopNotifications(request: request(characteristicUuid: nonExistentCharacteristicUuid))

        await #expect(throws: BluetoothError.noSuchCharacteristic(service: fakeServiceUuid, characteristic: nonExistentCharacteristicUuid)) {
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
