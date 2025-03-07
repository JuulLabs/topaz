import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage
import Testing
import XCTest

extension Tag {
    @Tag static var getDevices: Self
}

@Suite(.tags(.getDevices))
struct GetDevicesResponseTests {
    @Test
    func toJsMessage_withZeroPeripherals_hasEmptyArrayBody() throws {
        let sut = GetDevicesResponse(peripherals: [])
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSArray.self))
        #expect(body == [])
    }

    @Test
    func toJsMessage_withOnePeripheral_hasExpectedBody() throws {
        let sut = GetDevicesResponse(peripherals: [(id: UUID(n: 0), name: "Slartibartfast")])
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSArray.self))
        let responseDict0 = [
            "uuid": "00000000-0000-0000-0000-000000000000",
            "name": "Slartibartfast",
        ]
        #expect(body == [responseDict0])
    }

    @Test
    func toJsMessage_withTwoPeripherals_hasExpectedBody() throws {
        let sut = GetDevicesResponse(
            peripherals: [
                (id: UUID(n: 0), name: "Slarti"),
                (id: UUID(n: 1), name: "Bartfast"),
            ]
        )
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSArray.self))
        let responseDict0 = [
            "uuid": "00000000-0000-0000-0000-000000000000",
            "name": "Slarti",
        ]
        let responseDict1 = [
            "uuid": "00000000-0000-0000-0000-000000000001",
            "name": "Bartfast",
        ]
        #expect(body == [responseDict0, responseDict1])
    }
}

@Suite(.tags(.getDevices))
struct GetDevicesTests {
    @Test
    func execute_withClientProvidingOnePeripheral_respondsWithOneResult() async throws {
        var client = MockBluetoothClient()
        client.onGetPeripherals = { _ in
            [FakePeripheral(id: UUID(n: 0))]
        }
        let sut = GetDevices(request: GetDevicesRequest())
        let response = try await sut.execute(state: BluetoothState(), client: client)
        let jsMessage = response.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSArray.self))
        #expect(body.count == 1)
    }

    @Test
    func execute_withOneActivePeripheral_requestsSamePeripheralFromClient() async throws {
        let callbackExpectation = XCTestExpectation(description: "Client get peripherals")
        var client = MockBluetoothClient()
        client.onGetPeripherals = { uuids in
            #expect(uuids == [UUID(n: 0)])
            callbackExpectation.fulfill()
            return []
        }
        let state = BluetoothState(peripherals: [FakePeripheral(id: UUID(n: 0))])
        let sut = GetDevices(request: GetDevicesRequest())
        _ = try await sut.execute(state: state, client: client)
        let outcome = await XCTWaiter().fulfillment(of: [callbackExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }

    @Test(.disabled("rememberPeripheral is not yet implemented"))
    func execute_withOneRememberedPeripheral_requestsSamePeripheralFromClient() async throws {
        let callbackExpectation = XCTestExpectation(description: "Client get peripherals")
        var client = MockBluetoothClient()
        client.onGetPeripherals = { uuids in
            #expect(uuids == [UUID(n: 0)])
            callbackExpectation.fulfill()
            return []
        }
        let state = BluetoothState()
        await state.rememberPeripheral(UUID(n: 0))
        let sut = GetDevices(request: GetDevicesRequest())
        _ = try await sut.execute(state: state, client: client)
        let outcome = await XCTWaiter().fulfillment(of: [callbackExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }
}
