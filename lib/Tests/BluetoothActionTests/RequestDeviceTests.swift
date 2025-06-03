import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import DevicePicker
import EventBus
import Foundation
import JsMessage
import TestHelpers
import Testing

extension Tag {
    @Tag static var requestDevice: Self
}

@Suite(.tags(.requestDevice))
struct RequestDeviceResponseTests {
    @Test
    func toJsMessage_withoutName_hasExpectedBody() throws {
        let sut = RequestDeviceResponse(peripheralId: UUID(n: 0), name: nil)
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        let expectedResponse: NSDictionary = [
            "uuid": "00000000-0000-beef-cafe-000000000000",
            "name": NSNull(),
        ]
        #expect(body == expectedResponse)
    }

    @Test
    func toJsMessage_withName_hasExpectedBody() throws {
        let sut = RequestDeviceResponse(peripheralId: UUID(n: 0), name: "test-name")
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        let expectedResponse: NSDictionary = [
            "uuid": "00000000-0000-beef-cafe-000000000000",
            "name": "test-name",
        ]
        #expect(body == expectedResponse)
    }
}

@Suite(.tags(.requestDevice))
struct RequestDeviceTests {
    @Test
    func execute_withRequestForSingleService_determinesPermissionsFromInputFilters() async throws {
        let eventBus = await selfResolvingEventBus()
        let fakeService = FakeService(uuid: UUID(n: 10))
        let extraServiceUuid = UUID(n: 99)
        let fake = FakePeripheral(id: UUID(n: 0), connectionState: .connected, services: [fakeService])
        var client = MockBluetoothClient()
        client.onStartScanning = { _ in }
        client.onStopScanning = { }
        let options: [String: JsType] = [
            "filters": .array([
                .dictionary([
                    "services": .array([
                        .string(fakeService.uuid.uuidString),
                    ]),
                ]),
            ]),
            "optionalServices": .array([
                .string(extraServiceUuid.uuidString)
            ]),
        ]
        let selector = await MockDeviceSelector(onSelection: { .success(fake) })
        let state = BluetoothState(peripherals: [fake])
        let request = RequestDeviceRequest(rawOptionsData: options)
        let sut = RequestDevice(request: request, selector: selector)

        // Execute for a response:
        let response = try await sut.execute(state: state, client: client, eventBus: eventBus)
        #expect(response.peripheralId == fake.id)

        // Test that the peripheral state was updated with the expected permissions:
        let updatedPeripheral = try await state.getPeripheral(fake.id)
        switch updatedPeripheral.permissions.allowedServices {
        case .all:
            Issue.record("Unexpected permissions case")
        case let .restricted(allowedUuids):
            #expect(allowedUuids == [fakeService.uuid, extraServiceUuid])
        }
    }
}

private struct MockDeviceSelector: InteractiveDeviceSelector {
    let onSelection: () -> Result<Bluetooth.Peripheral, DeviceSelectionError>

    public init(
        onSelection: (() -> Result<Bluetooth.Peripheral, DeviceSelectionError>)? = nil,
    ) {
        self.onSelection = onSelection ?? { fatalError("Not implemented") }
    }

    public func awaitSelection() async -> Result<Bluetooth.Peripheral, DeviceSelectionError> {
        onSelection()
    }

    public func makeSelection(_ identifier: UUID) async {
        fatalError("Not implemented")
    }

    public func showAdvertisement(peripheral: Bluetooth.Peripheral, advertisement: Bluetooth.Advertisement) async {
        fatalError("Not implemented")
    }

    public func cancel() async {
        fatalError("Not implemented")
    }
}
