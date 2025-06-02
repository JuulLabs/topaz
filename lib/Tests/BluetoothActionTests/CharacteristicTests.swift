import Bluetooth
@testable import BluetoothAction
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import Testing

extension Tag {
    @Tag static var characteristic: Self
}

@Suite(.tags(.characteristic))
struct CharacteristicRequestTests {
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
        let request = CharacteristicRequest.decode(from: body)
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
        let request = CharacteristicRequest.decode(from: body)
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
        let request = CharacteristicRequest.decode(from: body)
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
        let request = CharacteristicRequest.decode(from: body)
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
        let request = CharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withEmptyBody_isNil() {
        let body: [String: JsType] = [:]
        let request = CharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }
}

@Suite(.tags(.characteristic))
struct CharacteristicResponseTests {
    @Test
    func toJsMessage_withDefaultResponse_hasExpectedBody() throws {
        let sut = CharacteristicResponse()
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        #expect(body == [:])
    }
}

@Suite(.tags(.characteristic))
struct CharacteristicChangedEventTests {
    @Test
    func characteristicValueChangedEvent_asJsValue_hasExpectedBody() throws {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let sut = CharacteristicChangedEvent(
            peripheralId: deviceUuid,
            serviceId: serviceUuid,
            characteristicId: characteristicUuid,
            instance: instance.uint32Value,
            data: nil
        )
        let jsEvent = sut.characteristicValueChangedEvent()

        // Convert the event to the Js representation
        let encoded = jsEvent.jsValue
        // Convert it back to the native representation so we can check the values
        let decoded = try #require(JsType.bridge(encoded).dictionary)
        let decodedBody = try #require(decoded["data"]?.dictionary)

        // Event properties
        #expect(decoded["id"]?.string == characteristicUuid.uuidString.lowercased())
        #expect(decoded["name"]?.string == "characteristicvaluechanged")

        // Event data properties
        #expect(decodedBody["device"]?.string == deviceUuid.uuidString.lowercased())
        #expect(decodedBody["service"]?.string == serviceUuid.uuidString.lowercased())
        #expect(decodedBody["characteristic"]?.string == characteristicUuid.uuidString.lowercased())
        #expect(decodedBody["instance"]?.number == instance)
    }
}
