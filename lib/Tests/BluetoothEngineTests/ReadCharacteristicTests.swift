import Bluetooth
@testable import BluetoothAction
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import Foundation
import JsMessage
import Testing

@Suite(.tags(.connect))
struct ReadCharacteristicRequestTests {
    @Test
    func decode_withInstance_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
        ]
        let request = ReadCharacteristicRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.characteristicInstance == instance.uint32Value)
    }

    @Test
    func decode_withoutInstance_isNil() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
        ]
        let request = ReadCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withExtraBodyData_succeedsAndIgnoresExtras() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "bananaCount": .number(42),
        ]
        let request = ReadCharacteristicRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.characteristicInstance == instance.uint32Value)
    }

    @Test
    func decode_withInvalidServiceUuid_isNil() {
        let deviceUuid = UUID(n: 0)
        let characteristicUuid = UUID(n: 2)
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string("bananaman"),
            "characteristic": .string(characteristicUuid.uuidString),
        ]
        let request = ReadCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withInvalidCharacteristicUuid_isNil() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string("bananaman"),
        ]
        let request = ReadCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withEmptyBody_isNil() {
        let body: [String: JsType] = [:]
        let request = ReadCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }
}

@Suite(.tags(.connect))
struct ReadCharacteristicResponseTests {
    @Test
    func toJsMessage_withDefaultResponse_hasExpectedBody() throws {
        let sut = ReadCharacteristicResponse()
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        #expect(body == [:])
    }
}
