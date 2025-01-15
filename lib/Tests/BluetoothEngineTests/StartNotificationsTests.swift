import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import Testing

extension Tag {
    @Tag static var startNotifications: Self
}

private let fakePeripheralId: UUID = UUID(n: 0)
private let fakeServiceUuid = UUID(n: 1)
private let fakeCharacteristicId = UUID(n: 2)
private let fakeCharacteristicInstance: UInt32 = 3

@Suite(.tags(.startNotifications))
struct StartNotificationsTests {

    private let peripheral = { (connectionState: ConnectionState, characteristic: Characteristic) in
        FakePeripheral(id: fakePeripheralId, connectionState: connectionState, services: [FakeService(uuid: fakeServiceUuid, characteristics: [characteristic])])
    }

    private var mockBluetoothClient: MockBluetoothClient = MockBluetoothClient()

    init() {
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: fakePeripheralId, characteristicId: fakeCharacteristicId, instance: fakeCharacteristicInstance)
        mockBluetoothClient.onStartNotifications = {_, _ in
            return basicCharacteristic
        }
    }

    @Test
    mutating func execute_withBasicPeripheral_callsStartNotifications() async throws {
        let startNotificationsWasCalledActor = StartNotificationsCalledActor()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: fakePeripheralId, characteristicId: fakeCharacteristicId, instance: fakeCharacteristicInstance)
        mockBluetoothClient.onStartNotifications = {_, _ in
            await startNotificationsWasCalledActor.gotCalled()
            return basicCharacteristic
        }
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        _ = try await sut.execute(state: state, client: mockBluetoothClient)

        #expect(await startNotificationsWasCalledActor.wasCalled)
    }

    @Test
    func execute_withNotifiableCharacteristic_noErrorIsThrown() async throws {
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: mockBluetoothClient)
        }
    }

    @Test
    func execute_withDisconnectedPeripheral_throwsDeviceNotConnectedError() async throws {
        let state = BluetoothState(peripherals: [peripheral(.disconnected, FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        do {
            _ = try await sut.execute(state: state, client: mockBluetoothClient)
            Issue.record("Should not reach this line. .deviceNotConnected error should have been thrown.")
        } catch {
            if case BluetoothError.deviceNotConnected = error {
                // No op. This is the correct error type
            } else {
                Issue.record(".deviceNotConnected error should have been thrown. \(error) was thrown instead.")
            }
        }
    }

    @Test
    func execute_characteristicNotFound_throwsNoSuchCharacteristicError() async throws {
        let nonExistentCharacteristicUuid = UUID(n: 7351)
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance, properties: [.notify]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: nonExistentCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        do {
            _ = try await sut.execute(state: state, client: mockBluetoothClient)
            Issue.record("Should not reach this line. .noSuchCharacteristic error should have been thrown.")
        } catch {
            if case BluetoothError.noSuchCharacteristic(service: fakeServiceUuid, characteristic: nonExistentCharacteristicUuid) = error {
                // No op. This is the correct error type
            } else {
                Issue.record(".noSuchCharacteristic error should have been thrown. \(error) was thrown instead.")
            }
        }
    }

    @Test
    func execute_characteristicHasNeitherNotifyNorIndicateSet_throwsCharacteristicNotificationsNotSupportedError() async throws {
        let characteristicWithoutNotifyOrIndicateProperties = FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance, properties: [])
        let state = BluetoothState(peripherals: [peripheral(.connected, characteristicWithoutNotifyOrIndicateProperties)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        do {
            _ = try await sut.execute(state: state, client: mockBluetoothClient)
            Issue.record("Should not reach this line. .notSupported error should have been thrown.")
        } catch {
            if case BluetoothError.characteristicNotificationsNotSupported(characteristic: fakeCharacteristicId) = error {
                // No op. This is the correct error type
            } else {
                Issue.record(".notSupported error should have been thrown. \(error) was thrown instead.")
            }
        }
    }

    @Test
    func execute_characteristicHasNotifySet_noErrorIsThrown() async throws {
        let characteristicWithNotifyProperty = FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance, properties: [.notify])
        let state = BluetoothState(peripherals: [peripheral(.connected, characteristicWithNotifyProperty)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: mockBluetoothClient)
        }
    }

    @Test
    func execute_characteristicHasIndicateSet_noErrorIsThrown() async throws {
        let characteristicWithNotifyProperty = FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance, properties: [.indicate])
        let state = BluetoothState(peripherals: [peripheral(.connected, characteristicWithNotifyProperty)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: mockBluetoothClient)
        }
    }

    @Test
    mutating func execute_characteristicIsAlreadyNotifying_clientShouldNotStartNotifications() async throws {
        let alreadyNotifyingCharacteristic = FakeCharacteristic(uuid: fakeCharacteristicId, instance: fakeCharacteristicInstance, properties: [.notify, .indicate], isNotifying: true)
        let startNotificationsWasCalledActor = StartNotificationsCalledActor()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: fakePeripheralId, characteristicId: fakeCharacteristicId, instance: fakeCharacteristicInstance)
        mockBluetoothClient.onStartNotifications = {_, _ in
            await startNotificationsWasCalledActor.gotCalled()
            return basicCharacteristic
        }

        let state = BluetoothState(peripherals: [peripheral(.connected, alreadyNotifyingCharacteristic)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicId, characteristicInstance: 3)
        let sut = StartNotifications(request: request)
        _ = try await sut.execute(state: state, client: mockBluetoothClient)
        #expect(await startNotificationsWasCalledActor.wasCalled == false)
    }
}

private actor StartNotificationsCalledActor {
    var wasCalled = false

    func gotCalled() {
        wasCalled = true
    }
}
