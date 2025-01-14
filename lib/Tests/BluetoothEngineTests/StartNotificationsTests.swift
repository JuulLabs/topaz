import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import Testing

extension Tag {
    @Tag static var startNotifications: Self
}

@Suite(.tags(.startNotifications))
struct StartNotificationsTests {

    private let zeroUuid: UUID = UUID(n: 0)
//    private let oneUuid: UUID = UUID(n: 1)
//    private let twoUuid: UUID = UUID(n: 2)

    private let peripheral = { (uuid: UUID, connectionState: ConnectionState, characteristic: Characteristic) in
        FakePeripheral(id: uuid, connectionState: connectionState, services: [FakeService(uuid: UUID(n: 1), characteristics: [characteristic])])
    }

//    private var mockBluetoothClient = MockBluetoothClient()

    @Test
    func execute_withBasicPeripheral_clientCallsStartNotifications() async throws {

        var mockBluetoothClient = MockBluetoothClient()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: UUID(n: 0), characteristicId: UUID(n: 2), instance: 3)
        let startNotificationsWasCalledActor = StartNotificationsCalledActor()
        mockBluetoothClient.onStartNotifications = {_, _ in
            await startNotificationsWasCalledActor.gotCalled()
            return basicCharacteristic
        }

        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .connected, FakeCharacteristic(uuid: UUID(n: 2), properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 1), characteristicUuid: UUID(n: 2), characteristicInstance: 3)
        let sut = StartNotifications(request: request)
        let _ = try await sut.execute(state: state, client: mockBluetoothClient)
        #expect(await startNotificationsWasCalledActor.wasCalled)
    }

    @Test
    func execute_withBasicPeripheral_noErrorIsThrown() async throws {

        var mockBluetoothClient = MockBluetoothClient()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: UUID(n: 0), characteristicId: UUID(n: 2), instance: 3)
        mockBluetoothClient.onStartNotifications = {_, _ in return basicCharacteristic }

        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .connected, FakeCharacteristic(uuid: UUID(n: 2), properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 1), characteristicUuid: UUID(n: 2), characteristicInstance: 3)
        let sut = StartNotifications(request: request)
        await #expect(throws: Never.self) {
            let _ = try await sut.execute(state: state, client: mockBluetoothClient)
        }
    }

    @Test
    func execute_withDisconnectedPeripheral_throwsDeviceNotConnectedError() async throws {

        var mockBluetoothClient = MockBluetoothClient()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: UUID(n: 0), characteristicId: UUID(n: 2), instance: 3)
        mockBluetoothClient.onStartNotifications = {_, _ in return basicCharacteristic }

        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .disconnected, FakeCharacteristic(uuid: UUID(n: 2)))])
        let request = CharacteristicRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 1), characteristicUuid: UUID(n: 2), characteristicInstance: 3)
        let sut = StartNotifications(request: request)
//        await #expect(throws: BluetoothError.deviceNotConnected) {
//            let response = try await sut.execute(state: state, client: mockBluetoothClient)
//        }

        do {
            let _ = try await sut.execute(state: state, client: mockBluetoothClient)
            // Should not reach here. Error should be thrown.
//            #expect(false)
            Issue.record("Should not reach this line. .deviceNotConnected error should have been thrown.")
        } catch {
            if case BluetoothError.deviceNotConnected = error {
                // No op. This is the correct error type
            } else {
                Issue.record(".deviceNotConnected error should have been thrown. \(error) was thrown instead.")
            }
        }
//        #expect(response.isConnected == true)
    }

    @Test
    func execute_characteristicHasNeitherNotifyNorIndicateSet_throwsNotSupportedError() async throws {
        var mockBluetoothClient = MockBluetoothClient()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: UUID(n: 0), characteristicId: UUID(n: 2), instance: 3)
        mockBluetoothClient.onStartNotifications = {_, _ in return basicCharacteristic }

        let characteristicWithoutNotifyOrIndicateProperties = FakeCharacteristic(uuid: UUID(n: 2), properties: [])

        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .connected, characteristicWithoutNotifyOrIndicateProperties)])
        let request = CharacteristicRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 1), characteristicUuid: UUID(n: 2), characteristicInstance: 3)
        let sut = StartNotifications(request: request)

        do {
            let _ = try await sut.execute(state: state, client: mockBluetoothClient)
            Issue.record("Should not reach this line. .notSupported error should have been thrown.")
        } catch {
            if case BluetoothError.notSupported = error {
                // No op. This is the correct error type
            } else {
                Issue.record(".notSupported error should have been thrown. \(error) was thrown instead.")
            }
        }
    }

    @Test
    func execute_characteristicHasNotifySet_noErrorIsThrown() async throws {
        var mockBluetoothClient = MockBluetoothClient()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: UUID(n: 0), characteristicId: UUID(n: 2), instance: 3)
        mockBluetoothClient.onStartNotifications = {_, _ in return basicCharacteristic }

        let characteristicWithNotifyProperty = FakeCharacteristic(uuid: UUID(n: 2), properties: [.notify])

        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .connected, characteristicWithNotifyProperty)])
        let request = CharacteristicRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 1), characteristicUuid: UUID(n: 2), characteristicInstance: 3)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            let _ = try await sut.execute(state: state, client: mockBluetoothClient)
        }
    }

    @Test
    func execute_characteristicHasIndicateSet_noErrorIsThrown() async throws {
        var mockBluetoothClient = MockBluetoothClient()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: UUID(n: 0), characteristicId: UUID(n: 2), instance: 3)
        mockBluetoothClient.onStartNotifications = {_, _ in return basicCharacteristic }

        let characteristicWithNotifyProperty = FakeCharacteristic(uuid: UUID(n: 2), properties: [.indicate])

        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .connected, characteristicWithNotifyProperty)])
        let request = CharacteristicRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 1), characteristicUuid: UUID(n: 2), characteristicInstance: 3)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            let _ = try await sut.execute(state: state, client: mockBluetoothClient)
        }
    }

    @Test
    func execute_characteristicIsAlreadyNotifying_clientShouldNotStartNotifications() async throws {
        var mockBluetoothClient = MockBluetoothClient()
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: UUID(n: 0), characteristicId: UUID(n: 2), instance: 3)
        let startNotificationsWasCalledActor = StartNotificationsCalledActor()
        mockBluetoothClient.onStartNotifications = {_, _ in
            await startNotificationsWasCalledActor.gotCalled()
            return basicCharacteristic
        }

        let state = BluetoothState(peripherals: [peripheral(zeroUuid, .connected, FakeCharacteristic(uuid: UUID(n: 2), properties: [.notify, .indicate], isNotifying: true))])
        let request = CharacteristicRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 1), characteristicUuid: UUID(n: 2), characteristicInstance: 3)
        let sut = StartNotifications(request: request)
        let _ = try await sut.execute(state: state, client: mockBluetoothClient)
        #expect(await startNotificationsWasCalledActor.wasCalled == false)
    }
}

private actor StartNotificationsCalledActor {
    var wasCalled = false

    func gotCalled() {
        wasCalled = true
    }
}

//@unchecked Sendable
//private class TestClient: BluetoothClient {
//
//    public var startNotificationsCalled: Bool = false
//
//    public let events: AsyncStream<any BluetoothEvent>
//
//    init(startNotificationsCalled: Bool, events: AsyncStream<any BluetoothEvent>) {
//        self.startNotificationsCalled = startNotificationsCalled
//        self.events = events
//    }
//
//    func enable() async {}
//    
//    func disable() async {}
//    
//    func resolvePendingRequests(for event: any BluetoothEvent) async {}
//    
//    func cancelPendingRequests() async {}
//    
//    func scan(filter: Bluetooth.Filter) async -> any BluetoothScanner {}
//    
//    func systemState() async throws -> SystemStateEvent {}
//    
//    func connect(_ peripheral: Bluetooth.Peripheral) async throws -> PeripheralEvent {}
//    
//    func disconnect(_ peripheral: Bluetooth.Peripheral) async throws -> PeripheralEvent {}
//    
//    func discoverServices(_ peripheral: Bluetooth.Peripheral, filter: Bluetooth.ServiceDiscoveryFilter) async throws -> ServiceDiscoveryEvent {}
//    
//    func discoverCharacteristics(_ peripheral: Bluetooth.Peripheral, filter: Bluetooth.CharacteristicDiscoveryFilter) async throws -> CharacteristicDiscoveryEvent {}
//    
//    func characteristicNotify(_ peripheral: Bluetooth.Peripheral, _ characteristic: Bluetooth.Characteristic, enabled: Bool) async throws -> CharacteristicEvent {}
//    
//    func characteristicRead(_ peripheral: Bluetooth.Peripheral, characteristic: Bluetooth.Characteristic) async throws -> CharacteristicChangedEvent {}
//    
//    func startNotifications(_ peripheral: Bluetooth.Peripheral, characteristic: Bluetooth.Characteristic) async throws -> CharacteristicEvent {
//        startNotificationsCalled = true
//    }
//    
//    func stopNotifications(_ peripheral: Bluetooth.Peripheral, characteristic: Bluetooth.Characteristic) async throws -> CharacteristicEvent {}
//    
//
//}
