import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage
import SecurityList
import Testing

extension Tag {
    @Tag static var characteristics: Self
}

@Suite(.tags(.characteristics))
struct WriteCharacteristicRequestTests {
    @Test
    func decode_withAllProperties_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let value: Data = Data("4".utf8)
        let withResponse: NSNumber = 1 // true
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "value": .string(value.base64EncodedString()),
            "withResponse": .number(withResponse),
        ]
        let request = WriteCharacteristicRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.characteristicInstance == instance.uint32Value)
        #expect(request?.value == value)
        #expect(request?.withResponse == true)
    }

    @Test
    func decode_withoutValue_isNil() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let withResponse: NSNumber = 1 // true
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "withResponse": .number(withResponse),
        ]
        let request = WriteCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withExtraBodyData_succeedsAndIgnoresExtras() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let value: Data = Data("4".utf8)
        let withResponse: NSNumber = 1 // true
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "value": .string(value.base64EncodedString()),
            "withResponse": .number(withResponse),
            "bananaCount": .number(42),
        ]
        let request = WriteCharacteristicRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.characteristicInstance == instance.uint32Value)
        #expect(request?.value == value)
        #expect(request?.withResponse == true)
    }

    @Test
    func decode_withInvalidServiceUuid_isNil() {
        let deviceUuid = UUID(n: 0)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 3
        let value: Data = Data("4".utf8)
        let withResponse: NSNumber = 1 // true
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string("bananaman"),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "value": .string(value.base64EncodedString()),
            "withResponse": .number(withResponse),
        ]
        let request = WriteCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withInvalidCharacteristicUuid_isNil() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let instance: NSNumber = 3
        let value: Data = Data("4".utf8)
        let withResponse: NSNumber = 1 // true
        let body: [String: JsType] = [
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string("bananaman"),
            "instance": .number(instance),
            "value": .string(value.base64EncodedString()),
            "withResponse": .number(withResponse),
        ]
        let request = WriteCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withEmptyBody_isNil() {
        let body: [String: JsType] = [:]
        let request = WriteCharacteristicRequest.decode(from: body)
        #expect(request == nil)
    }
}

@Suite(.tags(.characteristics))
struct WriteCharacteristicTests {
    @Test
    func execute_withCharacteristicBlockedForWriting_throwsBlocklistedError() async throws {
        let characteristicUuid = UUID(n: 31)
        let securityList = SecurityList(characteristics: [characteristicUuid: .writing])
        let state = BluetoothState(securityList: securityList)
        let request = WriteCharacteristicRequest(
            peripheralId: UUID(n: 0),
            serviceUuid: UUID(n: 30),
            characteristicUuid: characteristicUuid,
            characteristicInstance: 0,
            value: Data(),
            withResponse: false
        )
        let sut = WriteCharacteristic(request: request)
        await #expect(throws: BluetoothError.blocklisted(characteristicUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient())
        }
    }
}
