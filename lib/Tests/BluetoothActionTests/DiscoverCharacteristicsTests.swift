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
    @Tag static var discoverCharacteristics: Self
}

@Suite(.tags(.discoverCharacteristics))
struct DiscoverCharacteristicsRequestTests {
    @Test
    func decode_withSingleCharacteristic_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let body: [String: JsType] = [
            "single": .number(true),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
        ]
        let request = DiscoverCharacteristicsRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.query.characteristicUuid == characteristicUuid)
    }

    @Test
    func decode_withoutCharacteristic_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let body: [String: JsType] = [
            "single": .number(false),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
        ]
        let request = DiscoverCharacteristicsRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.query.characteristicUuid == nil)
    }

    @Test
    func decode_withNonSingleCharacteristic_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let characteristicUuid = UUID(n: 2)
        let body: [String: JsType] = [
            "single": .number(false),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
            "characteristic": .string(characteristicUuid.uuidString),
        ]
        let request = DiscoverCharacteristicsRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.serviceUuid == serviceUuid)
        #expect(request?.query.characteristicUuid == characteristicUuid)
    }
}

@Suite(.tags(.discoverCharacteristics))
struct DiscoverCharacteristicsResponseTests {
    @Test
    func toJsMessage_withSingleCharacteristic_hasExpectedBody() throws {
        let fake = FakeCharacteristic(uuid: UUID(n: 0), instance: 7, properties: [.notify])
        let sut = DiscoverCharacteristicsResponse(characteristics: [fake])
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        let bodyCharacteristicsArray = try #require(body["characteristics"]! as? NSArray)
        let characteristicBody = try #require(bodyCharacteristicsArray[0] as? NSDictionary)
        let expectedCharacteristicBody: NSDictionary = [
            "uuid": fake.uuid.uuidString,
            "instance": fake.instance,
            "properties": [
                "authenticatedSignedWrites": false,
                "broadcast": false,
                "indicate": false,
                "notify": true,
                "read": false,
                "reliableWrite": false,
                "writableAuxiliaries": false,
                "write": false,
                "writeWithoutResponse": false,
            ],
        ]
        #expect(bodyCharacteristicsArray.count == 1)
        #expect(characteristicBody == expectedCharacteristicBody)
    }
}

@Suite(.tags(.discoverCharacteristics))
struct DiscoverCharacteristicsTests {

    @Test
    func execute_withRequestForSingleCharacteristic_respondsWithSingleCharacteristic() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeService = FakeService(uuid: UUID(n: 30))
        let fakeCharacteristic = FakeCharacteristic(uuid: UUID(n: 31))
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: [fakeService])
        var client = MockBluetoothClient()
        client.onDiscoverCharacteristics = { peripheral, service, uuids in
            #expect(service.uuid == fakeService.uuid)
            #expect(uuids == [fakeCharacteristic.uuid])
            eventBus.enqueueEvent(
                CharacteristicDiscoveryEvent(peripheralId: peripheral.id, serviceId: service.uuid, characteristics: [fakeCharacteristic])
            )
        }
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverCharacteristicsRequest(peripheralId: fake.id, serviceUuid: fakeService.uuid, query: .first(fakeCharacteristic.uuid))
        let sut = DiscoverCharacteristics(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.characteristics == [fakeCharacteristic])
    }

    @Test
    func execute_withRequestForUnspecifiedCharacteristic_respondsWithAllCharacteristics() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeServices: [Service] = [
            FakeService(uuid: UUID(n: 10)),
            FakeService(uuid: UUID(n: 30)),
        ]
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: fakeServices)
        let fakeCharacteristics = [
            FakeCharacteristic(uuid: UUID(n: 31)),
            FakeCharacteristic(uuid: UUID(n: 32)),
        ]
        var client = MockBluetoothClient()
        client.onDiscoverCharacteristics = { peripheral, service, uuids in
            #expect(service.uuid == fakeServices[1].uuid)
            #expect(uuids == nil)
            eventBus.enqueueEvent(
                CharacteristicDiscoveryEvent(peripheralId: peripheral.id, serviceId: service.uuid, characteristics: fakeCharacteristics)
            )
        }
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverCharacteristicsRequest(peripheralId: fake.id, serviceUuid: fakeServices[1].uuid, query: .all(nil))
        let sut = DiscoverCharacteristics(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.characteristics == fakeCharacteristics)
    }

    @Test
    func execute_withRequestForNonSingleCharacteristic_respondsWithMatchingCharacteristic() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeServices: [Service] = [
            FakeService(uuid: UUID(n: 10)),
            FakeService(uuid: UUID(n: 30)),
        ]
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: fakeServices)
        let fakeCharacteristic = FakeCharacteristic(uuid: UUID(n: 31))
        var client = MockBluetoothClient()
        client.onDiscoverCharacteristics = { peripheral, service, uuids in
            #expect(service.uuid == fakeServices[1].uuid)
            #expect(uuids == [fakeCharacteristic.uuid])
            eventBus.enqueueEvent(
                CharacteristicDiscoveryEvent(peripheralId: peripheral.id, serviceId: service.uuid, characteristics: [fakeCharacteristic])
            )
        }
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverCharacteristicsRequest(peripheralId: fake.id, serviceUuid: fakeServices[1].uuid, query: .all(fakeCharacteristic.uuid))
        let sut = DiscoverCharacteristics(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.characteristics == [fakeCharacteristic])
    }

    @Test
    func execute_withBlockedCharacteristicUuid_throwsBlocklistedError() async throws {
        let characteristicUuid = UUID(n: 31)
        let securityList = SecurityList(characteristics: [characteristicUuid: .any])
        let state = BluetoothState(securityList: securityList)
        let request = DiscoverCharacteristicsRequest(peripheralId: UUID(n: 0), serviceUuid: UUID(n: 30), query: .first(characteristicUuid))
        let sut = DiscoverCharacteristics(request: request)
        await #expect(throws: BluetoothError.blocklisted(characteristicUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    @Test
    func execute_withBlockedServiceUuid_throwsBlocklistedError() async throws {
        let serviceUuid = UUID(n: 30)
        let securityList = SecurityList(services: [serviceUuid: .any])
        let state = BluetoothState(securityList: securityList)
        let request = DiscoverCharacteristicsRequest(peripheralId: UUID(n: 0), serviceUuid: serviceUuid, query: .all(nil))
        let sut = DiscoverCharacteristics(request: request)
        await #expect(throws: BluetoothError.blocklisted(serviceUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    @Test
    func execute_withRequestForUnspecifiedCharacteristic_respondsWithBlockedCharacteristicsRemoved() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeServices: [Service] = [
            FakeService(uuid: UUID(n: 10)),
            FakeService(uuid: UUID(n: 30)),
        ]
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: fakeServices)
        let allowed = FakeCharacteristic(uuid: UUID(n: 31))
        let blocked = FakeCharacteristic(uuid: UUID(n: 32))
        let fakeCharacteristics = [allowed, blocked]
        var client = MockBluetoothClient()
        client.onDiscoverCharacteristics = { peripheral, service, uuids in
            #expect(service.uuid == fakeServices[1].uuid)
            #expect(uuids == nil)
            eventBus.enqueueEvent(
                CharacteristicDiscoveryEvent(peripheralId: peripheral.id, serviceId: service.uuid, characteristics: fakeCharacteristics)
            )
        }
        let securityList = SecurityList(characteristics: [blocked.uuid: .any])
        let state = BluetoothState(peripherals: [fake], securityList: securityList)
        let request = DiscoverCharacteristicsRequest(peripheralId: fake.id, serviceUuid: fakeServices[1].uuid, query: .all(nil))
        let sut = DiscoverCharacteristics(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.characteristics == [allowed])
    }
}
