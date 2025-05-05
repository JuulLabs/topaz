import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage
import Testing

extension Tag {
    @Tag static var descriptors: Self
}
@Suite(.tags(.descriptors))
struct ReadDescriptorRequestTests {
    @Test
    func decode_withAllProperties_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let descriptorUuid = UUID(n: 4)
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "descriptor": .string(descriptorUuid.uuidString),
        ]
        let request = ReadDescriptorRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.instance == instance.uint32Value)
        #expect(request?.descriptorUuid == descriptorUuid)
    }

    @Test
    func decode_withExtraBodyData_succeedsAndIgnoresExtras() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let descriptorUuid = UUID(n: 4)
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "descriptor": .string(descriptorUuid.uuidString),
            "bananaCount": .number(42),
        ]
        let request = ReadDescriptorRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.instance == instance.uint32Value)
        #expect(request?.descriptorUuid == descriptorUuid)
    }

    @Test
    func decode_withInvalidServiceUuid_isNil() {
        let deviceUuid = UUID(n: 0)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let descriptorUuid = UUID(n: 4)
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string("bananaman"),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "descriptor": .string(descriptorUuid.uuidString),
        ]
        let request = ReadDescriptorRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withInvalidDescriptorUuid_isNil() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "descriptor": .string("bananaman"),
        ]
        let request = ReadDescriptorRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withEmptyBody_isNil() {
        let body: [String: JsType] = [:]
        let request = ReadDescriptorRequest.decode(from: body)
        #expect(request == nil)
    }
}

@Suite(.tags(.descriptors))
struct ReadDescriptorResponseTests {
    @Test
    func toJsMessage_withDefaultResponse_hasExpectedBody() throws {
        let data = Data([0x01, 0x02])
        let sut = ReadDescriptorResponse(data: data)
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: String.self))
        let decoded = Data(base64Encoded: body) ?? Data()
        #expect(decoded == data)
    }
}
