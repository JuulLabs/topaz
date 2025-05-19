import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList
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

@Suite(.tags(.descriptors))
struct ReadDescriptorTests {
    @Test
    func execute_withSuccessfulReadEvent_respondsWithData() async throws {
        let expectedData = Data("Hello".utf8)
        let fake = fakePeripheralWithDescriptor()
        let client = clientThatSucceeds(with: expectedData)
        let state = BluetoothState(peripherals: [fake])
        let request = ReadDescriptorRequest(
            peripheralId: fake.id,
            serviceUuid: fake.services[0].uuid,
            characteristicUuid: fake.services[0].characteristics[0].uuid,
            instance: fake.services[0].characteristics[0].instance,
            descriptorUuid: fake.services[0].characteristics[0].descriptors[0].uuid
        )
        let sut = ReadDescriptor(request: request)
        let response = try await sut.execute(state: state, client: client)
        #expect(response.data == expectedData)
    }

    @Test
    func execute_withDescriptorBlockedForReading_throwsBlocklistedError() async throws {
        let descriptorUuid = UUID(n: 40)
        let securityList = SecurityList(descriptors: [descriptorUuid: .reading])
        let state = BluetoothState(securityList: securityList)
        let request = ReadDescriptorRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 30), characteristicUuid: UUID(n: 31), instance: 0, descriptorUuid: descriptorUuid)
        let sut = ReadDescriptor(request: request)
        await #expect(throws: BluetoothError.blocklisted(descriptorUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient())
        }
    }

    @Test
    func execute_withDescriptorBlockedForWriting_doesNotThrow() async throws {
        let fake = fakePeripheralWithDescriptor()
        let descriptorUuid = fake.services[0].characteristics[0].descriptors[0].uuid
        let client = clientThatSucceeds(with: Data())
        let securityList = SecurityList(descriptors: [descriptorUuid: .writing])
        let state = BluetoothState(peripherals: [fake], securityList: securityList)
        let request = ReadDescriptorRequest(
            peripheralId: fake.id,
            serviceUuid: fake.services[0].uuid,
            characteristicUuid: fake.services[0].characteristics[0].uuid,
            instance: fake.services[0].characteristics[0].instance,
            descriptorUuid: descriptorUuid
        )
        let sut = ReadDescriptor(request: request)
        await #expect(throws: Never.self) {
            _ = try await sut.execute(state: state, client: client)
        }
    }

    private func fakePeripheralWithDescriptor() -> Peripheral {
        let fakeDescriptor = FakeDescriptor(uuid: UUID(n: 40))
        let fakeCharacteristic = FakeCharacteristic(uuid: UUID(n: 31), descriptors: [fakeDescriptor])
        let fakeService = FakeService(uuid: UUID(n: 30), characteristics: [fakeCharacteristic])
        return FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: [fakeService])
    }

    private func clientThatSucceeds(with data: Data) -> BluetoothClient {
        var client = MockBluetoothClient()
        client.onDescriptorRead = { peripheral, characteristic, descriptor in
            return DescriptorChangedEvent(
                peripheralId: peripheral.id,
                characteristicId: characteristic.uuid,
                instance: characteristic.instance,
                descriptorId: descriptor.uuid,
                data: data
            )
        }
        return client
    }
}
