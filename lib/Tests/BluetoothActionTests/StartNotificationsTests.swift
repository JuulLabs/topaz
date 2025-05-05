import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
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

@Suite(.tags(.startNotifications))
struct StartNotificationsTests {

    private let peripheral = { (connectionState: ConnectionState, characteristic: Characteristic) in
        FakePeripheral(id: fakePeripheralId, connectionState: connectionState, services: [FakeService(uuid: fakeServiceUuid, characteristics: [characteristic])])
    }

    @Test
    func execute_withBasicPeripheral_clientShouldStartNotifications() async throws {
        let basicCharacteristic = CharacteristicEvent(.characteristicNotify, peripheralId: fakePeripheralId, serviceId: fakeServiceUuid, characteristicId: fakeCharacteristicUuid, instance: fakeCharacteristicInstance)
        let startInvokedExpectation = XCTestExpectation(description: "onStartNotifications invoked")
        let mockBluetoothClient = mockBluetoothClient {
            $0.onCharacteristicSetNotifications = { _, _, startNotifying in
                if startNotifying {
                    startInvokedExpectation.fulfill()
                }
                return basicCharacteristic
            }
        }
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        _ = try await sut.execute(state: state, client: mockBluetoothClient)

        let outcome = await XCTWaiter().fulfillment(of: [startInvokedExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }

    @Test
    func execute_withNotifiableCharacteristic_noErrorIsThrown() async throws {
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify, .indicate]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
        }
    }

    @Test
    func execute_withDisconnectedPeripheral_throwsDeviceNotConnectedError() async throws {
        let state = BluetoothState(peripherals: [peripheral(.disconnected, FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
        } throws: { (error: any Error) in
            guard case .deviceNotConnected = (error as? BluetoothError) else {
                return false
            }
            return true
        }
    }

    @Test
    func execute_characteristicNotFound_throwsNoSuchCharacteristicError() async throws {
        let nonExistentCharacteristicUuid = UUID(n: 7351)
        let state = BluetoothState(peripherals: [peripheral(.connected, FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify]))])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: nonExistentCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
        } throws: { (error: any Error) in
            guard case .noSuchCharacteristic(service: fakeServiceUuid, characteristic: nonExistentCharacteristicUuid) = (error as? BluetoothError) else {
                return false
            }
            return true
        }
    }

    @Test
    func execute_characteristicHasNeitherNotifyNorIndicateSet_throwsCharacteristicNotificationsNotSupportedError() async throws {
        let characteristicWithoutNotifyOrIndicateProperties = FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [])
        let state = BluetoothState(peripherals: [peripheral(.connected, characteristicWithoutNotifyOrIndicateProperties)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
        } throws: { (error: any Error) in
            guard case .characteristicNotificationsNotSupported(characteristic: fakeCharacteristicUuid) = (error as? BluetoothError) else {
                return false
            }
            return true
        }
    }

    @Test
    func execute_characteristicHasNotifySet_noErrorIsThrown() async throws {
        let characteristicWithNotifyProperty = FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify])
        let state = BluetoothState(peripherals: [peripheral(.connected, characteristicWithNotifyProperty)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
        }
    }

    @Test
    func execute_characteristicHasIndicateSet_noErrorIsThrown() async throws {
        let characteristicWithNotifyProperty = FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.indicate])
        let state = BluetoothState(peripherals: [peripheral(.connected, characteristicWithNotifyProperty)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: fakeCharacteristicInstance)
        let sut = StartNotifications(request: request)

        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: mockBluetoothClient())
        }
    }

    @Test
    func execute_characteristicIsAlreadyNotifying_clientShouldNotStartNotifications() async throws {
        let alreadyNotifyingCharacteristic = FakeCharacteristic(uuid: fakeCharacteristicUuid, instance: fakeCharacteristicInstance, properties: [.notify, .indicate], isNotifying: true)
        let basicCharacteristic = CharacteristicEvent(.characteristicNotify, peripheralId: fakePeripheralId, serviceId: fakeServiceUuid, characteristicId: fakeCharacteristicUuid, instance: fakeCharacteristicInstance)
        let startInvokedExpectation = XCTestExpectation(description: "onStartNotifications invoked")
        startInvokedExpectation.isInverted = true
        let mockBluetoothClient = mockBluetoothClient {
            $0.onCharacteristicSetNotifications = { _, _, startNotifying in
                if startNotifying {
                    startInvokedExpectation.fulfill()
                }
                return basicCharacteristic
            }
        }
        let state = BluetoothState(peripherals: [peripheral(.connected, alreadyNotifyingCharacteristic)])
        let request = CharacteristicRequest(peripheralId: fakePeripheralId, serviceUuid: fakeServiceUuid, characteristicUuid: fakeCharacteristicUuid, characteristicInstance: 3)
        let sut = StartNotifications(request: request)

        _ = try await sut.execute(state: state, client: mockBluetoothClient)

        let outcome = await XCTWaiter().fulfillment(of: [startInvokedExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }
}

private func mockBluetoothClient(modify: ((inout MockBluetoothClient) -> Void)? = nil) -> MockBluetoothClient {
    var client = MockBluetoothClient()
    let basicCharacteristic = CharacteristicEvent(.characteristicNotify, peripheralId: fakePeripheralId, serviceId: fakeServiceUuid, characteristicId: fakeCharacteristicUuid, instance: fakeCharacteristicInstance)
    client.onCharacteristicSetNotifications = { _, _, _ in
        basicCharacteristic
    }
    modify?(&client)
    return client
}
