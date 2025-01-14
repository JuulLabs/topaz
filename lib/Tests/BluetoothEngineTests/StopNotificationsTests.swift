import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import Testing

extension Tag {
    @Tag static var stopNotifications: Self
}

private let fakePeripheralId: UUID = UUID(n: 0)
private let fakeServiceUuid = UUID(n: 1)
private let fakeCharacteristicId = UUID(n: 2)

@Suite(.tags(.stopNotifications))
struct StopNotificationsTests {

    private let peripheral = { (connectionState: ConnectionState, characteristic: Characteristic) in
        FakePeripheral(id: fakePeripheralId, connectionState: connectionState, services: [FakeService(uuid: fakeServiceUuid, characteristics: [characteristic])])
    }

    private var mockBluetoothClient: MockBluetoothClient = MockBluetoothClient()

    init() {
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: fakePeripheralId, characteristicId: fakeCharacteristicId, instance: 3)
        mockBluetoothClient.onStopNotifications = {_, _ in
            return basicCharacteristic
        }
    }

    @Test
    mutating func execute_withBasicPeripheral_callsStopNotifications() async throws {
        let stopNotificationsWasCalledActor = StopNotificationsCalledActor()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: fakePeripheralId, characteristicId: fakeCharacteristicId, instance: 3)
        mockBluetoothClient.onStopNotifications = {_, _ in
            await stopNotificationsWasCalledActor.gotCalled()
            return basicCharacteristic
        }
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicId, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: 3)
        let sut = StopNotifications(request: request)

        let _ = try await sut.execute(state: state, client: mockBluetoothClient)

        #expect(await stopNotificationsWasCalledActor.wasCalled)
    }

    @Test
    func execute_withNotifiableCharacteristic_noErrorIsThrown() async throws {
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicId, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: 3)
        let sut = StopNotifications(request: request)

        await #expect(throws: Never.self) {
            let _ = try await sut.execute(state: state, client: mockBluetoothClient)
        }
    }

    @Test
    func execute_characteristicNotFound_throwsNoSuchCharacteristicError() async throws {
        let nonExistentCharacteristicUuid = UUID(n: 7351)
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicId, properties: [.notify]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: nonExistentCharacteristicUuid, characteristicInstance: 3)
        let sut = StopNotifications(request: request)

        do {
            let _ = try await sut.execute(state: state, client: mockBluetoothClient)
            Issue.record("Should not reach this line. .noSuchCharacteristic error should have been thrown.")
        } catch {
            if case BluetoothError.noSuchCharacteristic(service: fakeServiceUuid, characteristic: nonExistentCharacteristicUuid) = error {
                // No op. This is the correct error type
            } else {
                Issue.record(".noSuchCharacteristic error should have been thrown. \(error) was thrown instead.")
            }
        }
    }
}

private actor StopNotificationsCalledActor {
    var wasCalled = false

    func gotCalled() {
        wasCalled = true
    }
}

