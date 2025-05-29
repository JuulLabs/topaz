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
    @Tag static var discoverServices: Self
}

@Suite(.tags(.discoverServices))
struct DiscoverServicesRequestTests {
    @Test
    func decode_withSingleService_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let body: [String: JsType] = [
            "single": .number(true),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
        ]
        let request = DiscoverServicesRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.query.serviceUuid == serviceUuid)
    }

    @Test
    func decode_withoutService_succeeds() {
        let deviceUuid = UUID(n: 0)
        let body: [String: JsType] = [
            "single": .number(false),
            "device": .string(deviceUuid.uuidString),
        ]
        let request = DiscoverServicesRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.query.serviceUuid == nil)
    }

    @Test
    func decode_withNonSingleDescriptor_succeeds() {
        let deviceUuid = UUID(n: 0)
        let serviceUuid = UUID(n: 1)
        let body: [String: JsType] = [
            "single": .number(false),
            "device": .string(deviceUuid.uuidString),
            "service": .string(serviceUuid.uuidString),
        ]
        let request = DiscoverServicesRequest.decode(from: body)
        #expect(request?.peripheralId == deviceUuid)
        #expect(request?.query.serviceUuid == serviceUuid)
    }
}

@Suite(.tags(.discoverServices))
struct DiscoverServicesResponseTests {
    @Test
    func toJsMessage_withSingleDescriptor_hasExpectedBody() throws {
        let fake = FakeService(uuid: UUID(n: 10))
        let sut = DiscoverServicesResponse(services: [fake])
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        let bodyServicesArray = try #require(body["services"]! as? NSArray)
        let expectedUuidArray: NSArray = [
            fake.uuid.uuidString.lowercased(),
        ]
        #expect(bodyServicesArray.count == 1)
        #expect(bodyServicesArray == expectedUuidArray)
    }

    @Test
    func toJsMessage_withMultipleDescriptors_hasExpectedBody() throws {
        let fakeServices = [
            FakeService(uuid: UUID(n: 1)),
            FakeService(uuid: UUID(uuidString: "00000000-0000-0000-0000-00000BA7F00D")!),
        ]
        let sut = DiscoverServicesResponse(services: fakeServices)
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        let bodyServicesArray = try #require(body["services"]! as? NSArray)
        let expectedUuidArray = fakeServices.map { service in
            service.uuid.uuidString.lowercased()
        } as NSArray
        #expect(bodyServicesArray.count == 2)
        #expect(bodyServicesArray == expectedUuidArray)
    }
}

@Suite(.tags(.discoverServices))
struct DiscoverServicesTests {
    @Test
    func execute_withRequestForSingleService_respondsWithSingleService() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeServices = [
            FakeService(uuid: UUID(n: 10)),
            FakeService(uuid: UUID(n: 11)),
        ]
        let matchingService = fakeServices[1]
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: fakeServices)
        var client = MockBluetoothClient()
        client.onDiscoverServices = { peripheral, uuids in
            #expect(uuids == [matchingService.uuid])
            eventBus.enqueueEvent(
                ServiceDiscoveryEvent(peripheralId: peripheral.id, services: [matchingService])
            )
        }
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverServicesRequest(peripheralId: fake.id, query: .first(matchingService.uuid))
        let sut = DiscoverServices(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.services == [matchingService])
    }

    @Test
    func execute_withRequestForUnspecifiedservice_respondsWithAllServices() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeServices = [
            FakeService(uuid: UUID(n: 10)),
            FakeService(uuid: UUID(n: 11)),
        ]
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: fakeServices)
        var client = MockBluetoothClient()
        client.onDiscoverServices = { peripheral, uuids in
            #expect(uuids == nil)
            eventBus.enqueueEvent(
                ServiceDiscoveryEvent(peripheralId: peripheral.id, services: fakeServices)
            )
        }
        let state = BluetoothState(peripherals: [fake])
        let request = DiscoverServicesRequest(peripheralId: fake.id, query: .all(nil))
        let sut = DiscoverServices(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.services == fakeServices)
    }

    @Test
    func execute_withRequestForBlockedServiceUuid_throwsBlocklistedError() async throws {
        let serviceUuid = UUID(n: 10)
        let securityList = SecurityList(services: [serviceUuid: .any])
        let state = BluetoothState(securityList: securityList)
        let request = DiscoverServicesRequest(peripheralId: UUID(n: 0), query: .first(serviceUuid))
        let sut = DiscoverServices(request: request)
        await #expect(throws: BluetoothError.blocklisted(serviceUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    @Test
    func execute_withRequestForAllServices_respondsWithBlockedServicesRemoved() async throws {
        let eventBus = await selfResolvingEventBus()
        let allowedService = FakeService(uuid: UUID(n: 10))
        let blockedService = FakeService(uuid: UUID(n: 11))
        let fakeServices = [allowedService, blockedService]
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: fakeServices)
        var client = MockBluetoothClient()
        client.onDiscoverServices = { peripheral, _ in
            eventBus.enqueueEvent(
                ServiceDiscoveryEvent(peripheralId: peripheral.id, services: fakeServices)
            )
        }
        let securityList = SecurityList(services: [blockedService.uuid: .any])
        let state = BluetoothState(peripherals: [fake], securityList: securityList)
        let request = DiscoverServicesRequest(peripheralId: UUID(n: 0), query: .all(nil))
        let sut = DiscoverServices(request: request)
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.services == [allowedService])
    }
}
