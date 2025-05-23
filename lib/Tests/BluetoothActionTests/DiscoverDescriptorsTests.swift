import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import EventBus
import Foundation
import JsMessage
import SecurityList
import TestHelpers
import Testing

extension Tag {
    @Tag static var discoverDescriptors: Self
}

@Suite(.tags(.discoverDescriptors))
struct DiscoverDescriptorsRequestTests {
    @Test
    func decode_withSingleDescriptor_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 2
        let descriptorUuid = UUID(n: 3)
        let body: [String: JsType] = [
            "single": .number(true),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "descriptor": .string(descriptorUuid.uuidString),
        ]
        let request = DiscoverDescriptorsRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.instance == instance.uint32Value)
        #expect(request?.query.descriptorUuid == descriptorUuid)
    }

    @Test
    func decode_withoutDescriptor_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 2
        let body: [String: JsType] = [
            "single": .number(false),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
        ]
        let request = DiscoverDescriptorsRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.instance == instance.uint32Value)
        #expect(request?.query.descriptorUuid == nil)
    }

    @Test
    func decode_withNonSingleDescriptor_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let instance: NSNumber = 2
        let descriptorUuid = UUID(n: 3)
        let body: [String: JsType] = [
            "single": .number(false),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
            "instance": .number(instance),
            "descriptor": .string(descriptorUuid.uuidString),
        ]
        let request = DiscoverDescriptorsRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.characteristicUuid == characteristicUuid)
        #expect(request?.instance == instance.uint32Value)
        #expect(request?.query.descriptorUuid == descriptorUuid)
    }
}

@Suite(.tags(.discoverDescriptors))
struct DiscoverDescriptorsResponseTests {
    @Test
    func toJsMessage_withSingleDescriptor_hasExpectedBody() throws {
        let fake = FakeDescriptor(uuid: UUID(n: 1), value: .none)
        let sut = DiscoverDescriptorsResponse(descriptors: [fake])
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSArray.self))
        let expectedBody: NSArray = [
            fake.uuid.uuidString.lowercased(),
        ]
        #expect(body.count == 1)
        #expect(body == expectedBody)
    }

    @Test
    func toJsMessage_withMultipleDescriptors_hasExpectedBody() throws {
        let fakeDescriptors = [
            FakeDescriptor(uuid: UUID(n: 1), value: .none),
            FakeDescriptor(uuid: UUID(uuidString: "00000000-0000-0000-0000-00000BA7F00D")!, value: .none),
        ]
        let sut = DiscoverDescriptorsResponse(descriptors: fakeDescriptors)
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSArray.self))
        let expectedBody = fakeDescriptors.map { descriptor in
            descriptor.uuid.uuidString.lowercased()
        } as NSArray
        #expect(body.count == 2)
        #expect(body == expectedBody)
    }
}

@Suite(.tags(.discoverDescriptors))
struct DiscoverDescriptorsTests {
    @Test
    func execute_withRequestForSingleDescriptor_respondsWithSingleDescriptor() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeDescriptors = [
            FakeDescriptor(uuid: UUID(n: 40)),
            FakeDescriptor(uuid: UUID(n: 41)),
        ]
        let matchingDescriptor = fakeDescriptors[1]
        let fakeCharacteristic = FakeCharacteristic(uuid: UUID(n: 31))
        let fakeService = FakeService(uuid: UUID(n: 30), characteristics: [fakeCharacteristic])
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: [fakeService])
        let client = clientThatSucceeds(with: fakeDescriptors, eventBus: eventBus)
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverDescriptorsRequest(
            peripheralId: fake.id,
            serviceUuid: fakeService.uuid,
            characteristicUuid: fakeCharacteristic.uuid,
            instance: fakeCharacteristic.instance,
            query: .first(matchingDescriptor.uuid)
        )
        let sut = DiscoverDescriptors(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.descriptors == [matchingDescriptor])
    }

    @Test
    func execute_withRequestForUnspecifiedDescriptor_respondsWithAllDescriptors() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeDescriptors = [
            FakeDescriptor(uuid: UUID(n: 40)),
            FakeDescriptor(uuid: UUID(n: 41)),
        ]
        let fakeCharacteristic = FakeCharacteristic(uuid: UUID(n: 31))
        let fakeService = FakeService(uuid: UUID(n: 30), characteristics: [fakeCharacteristic])
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: [fakeService])
        let client = clientThatSucceeds(with: fakeDescriptors, eventBus: eventBus)
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverDescriptorsRequest(
            peripheralId: fake.id,
            serviceUuid: fakeService.uuid,
            characteristicUuid: fakeCharacteristic.uuid,
            instance: fakeCharacteristic.instance,
            query: .all(nil)
        )
        let sut = DiscoverDescriptors(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.descriptors == fakeDescriptors)
    }

    @Test
    func execute_withRequestForNonSingleDescriptor_respondsWithMatchingDescriptor() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeDescriptors = [
            FakeDescriptor(uuid: UUID(n: 40)),
            FakeDescriptor(uuid: UUID(n: 41)),
        ]
        let matchingDescriptor = fakeDescriptors[1]
        let fakeCharacteristic = FakeCharacteristic(uuid: UUID(n: 31))
        let fakeService = FakeService(uuid: UUID(n: 30), characteristics: [fakeCharacteristic])
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: [fakeService])
        let client = clientThatSucceeds(with: fakeDescriptors, eventBus: eventBus)
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverDescriptorsRequest(
            peripheralId: fake.id,
            serviceUuid: fakeService.uuid,
            characteristicUuid: fakeCharacteristic.uuid,
            instance: fakeCharacteristic.instance,
            query: .all(matchingDescriptor.uuid)
        )
        let sut = DiscoverDescriptors(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.descriptors == [matchingDescriptor])
    }

    @Test
    func execute_withBlockedDescriptorUuid_throwsBlocklistedError() async throws {
        let descriptorUuid = UUID(n: 40)
        let securityList = SecurityList(descriptors: [descriptorUuid: .any])
        let state = BluetoothState(securityList: securityList)
        let request = DiscoverDescriptorsRequest(
            peripheralId: UUID(n: 0),
            serviceUuid: UUID(n: 10),
            characteristicUuid: UUID(n: 30),
            instance: 0,
            query: .first(descriptorUuid)
        )
        let sut = DiscoverDescriptors(request: request)
        await #expect(throws: BluetoothError.blocklisted(descriptorUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    @Test
    func execute_withBlockedServiceUuid_throwsBlocklistedError() async throws {
        let serviceUuid = UUID(n: 10)
        let securityList = SecurityList(services: [serviceUuid: .any])
        let state = BluetoothState(securityList: securityList)
        let request = DiscoverDescriptorsRequest(
            peripheralId: UUID(n: 0),
            serviceUuid: serviceUuid,
            characteristicUuid: UUID(n: 30),
            instance: 0,
            query: .all(nil)
        )
        let sut = DiscoverDescriptors(request: request)
        await #expect(throws: BluetoothError.blocklisted(serviceUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    @Test
    func execute_withBlockedCharacteristicUuid_throwsBlocklistedError() async throws {
        let characteristicUuid = UUID(n: 30)
        let securityList = SecurityList(characteristics: [characteristicUuid: .any])
        let state = BluetoothState(securityList: securityList)
        let request = DiscoverDescriptorsRequest(
            peripheralId: UUID(n: 0),
            serviceUuid: UUID(n: 10),
            characteristicUuid: characteristicUuid,
            instance: 0,
            query: .all(nil)
        )
        let sut = DiscoverDescriptors(request: request)
        await #expect(throws: BluetoothError.blocklisted(characteristicUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    private func clientThatSucceeds(with descriptors: [Descriptor], eventBus: EventBus) -> BluetoothClient {
        var client = MockBluetoothClient()
        client.onDiscoverDescriptors = { peripheral, characteristic in
            eventBus.enqueueEvent(
                DescriptorDiscoveryEvent(
                    peripheralId: peripheral.id,
                    serviceId: peripheral.services[0].uuid,
                    characteristicId: characteristic.uuid,
                    instance: characteristic.instance,
                    descriptors: descriptors
                )
            )
        }
        return client
    }
}
