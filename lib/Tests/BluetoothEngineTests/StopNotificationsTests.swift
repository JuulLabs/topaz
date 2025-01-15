import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import Testing
import XCTest

extension Tag {
    @Tag static var stopNotifications: Self
}

private let fakePeripheralId = UUID(n: 0)
private let fakeServiceUuid = UUID(n: 1)
private let fakeCharacteristicUuid = UUID(n: 2)
private let fakeCharacteristicInstance: UInt32 = 3

@Suite(.tags(.stopNotifications))
struct StopNotificationsTests {

    private let peripheral = { (connectionState: ConnectionState, characteristic: Characteristic) in
        FakePeripheral(id: fakePeripheralId, connectionState: connectionState, services: [FakeService(uuid: fakeServiceUuid, characteristics: [characteristic])])
    }

    @Test
    func execute_withBasicPeripheral_callsStopNotifications() async throws {
        let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: fakePeripheralId, characteristicId: fakeCharacteristicUuid, instance: fakeCharacteristicInstance)
        let stopInvokedExpectation = XCTestExpectation(description: "onStopNotifications invoked")
        let mockBluetoothClient = mockBluetoothClient {
            $0.onStopNotifications = { _, _ in
                stopInvokedExpectation.fulfill()
                return basicCharacteristic
            }
        }
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StopNotifications(request: request)

        _ = try await sut.execute(state: state, client: mockBluetoothClient)

        let outcome = await XCTWaiter().fulfillment(of: [stopInvokedExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }

    @Test
    func execute_withNotifiableCharacteristic_noErrorIsThrown() async throws {
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StopNotifications(request: request)

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
        }
    }

    @Test
    func execute_characteristicNotFound_throwsNoSuchCharacteristicError() async throws {
        let nonExistentCharacteristicUuid = UUID(n: 7351)
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: nonExistentCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StopNotifications(request: request)

        do {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
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

private func mockBluetoothClient(modify: ((inout MockBluetoothClient) -> Void)? = nil) -> MockBluetoothClient {
    var client = MockBluetoothClient()
    let basicCharacteristic = CharacteristicEvent(.startNotifications, peripheralId: fakePeripheralId, characteristicId: fakeCharacteristicUuid, instance: fakeCharacteristicInstance)
    client.onStopNotifications = { _, _ in
        basicCharacteristic
    }
    modify?(&client)
    return client
}
