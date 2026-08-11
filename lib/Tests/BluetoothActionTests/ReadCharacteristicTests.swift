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
    @Tag static var readCharacteristic: Self
}

private let fakePeripheralId = UUID(n: 0)
private let fakeServiceUuid = UUID(n: 1)
private let fakeCharacteristicUuid = UUID(n: 2)
private let fakeCharacteristicInstance: UInt32 = 3

@MainActor
private final class DeliveryBarrier {
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var isWaiting = false
    var didReply = false

    func wait() async {
        isWaiting = true
        await withCheckedContinuation { continuation = $0 }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
}

@Suite(.tags(.readCharacteristic), .timeLimit(.minutes(1)))
struct ReadCharacteristicTests {
    @Test
    func execute_holdsTheReplyUntilTheValueChangedEventReachesThePage() async throws {
        let eventBus = await selfResolvingEventBus()
        let barrier = await DeliveryBarrier()
        await eventBus.setJsContext(
            JsContext(
                id: JsContextIdentifier(tab: 0, url: URL(string: "https://test.com")!),
                eventSink: { _ in .success(()) },
                awaitPendingDeliveries: { await barrier.wait() }
            )
        )
        var client = MockBluetoothClient()
        client.onCharacteristicRead = { peripheral, characteristic in
            eventBus.enqueueEvent(
                CharacteristicChangedEvent(
                    peripheralId: peripheral.id,
                    serviceId: fakeServiceUuid,
                    characteristicId: characteristic.uuid,
                    instance: characteristic.instance,
                    data: Data("Hello".utf8)
                )
            )
        }
        let state = BluetoothState(peripherals: [fakePeripheral()])
        let sut = ReadCharacteristic(request: request())

        let read = Task {
            _ = try await sut.execute(state: state, client: client, eventBus: eventBus)
            await MainActor.run { barrier.didReply = true }
        }
        let deadline = ContinuousClock.now + .seconds(5)
        while await barrier.isWaiting == false, ContinuousClock.now < deadline {
            await Task.bigYield()
        }

        // The page reads the value out of the event, so the reply must not overtake it
        #expect(await barrier.isWaiting)
        #expect(await barrier.didReply == false)

        await barrier.release()
        try await read.value
        #expect(await barrier.didReply)
    }

    @Test
    func execute_withCharacteristicBlockedForReading_throwsBlocklistedError() async throws {
        let securityList = SecurityList(characteristics: [fakeCharacteristicUuid: .reading])
        let state = BluetoothState(peripherals: [fakePeripheral()], securityList: securityList)
        let sut = ReadCharacteristic(request: request())
        await #expect(throws: BluetoothError.blocklisted(fakeCharacteristicUuid)) {
            _ = try await sut.execute(state: state, client: MockBluetoothClient(), eventBus: EventBus())
        }
    }

    private func request() -> CharacteristicRequest {
        CharacteristicRequest(
            peripheralId: fakePeripheralId,
            serviceUuid: fakeServiceUuid,
            characteristicUuid: fakeCharacteristicUuid,
            characteristicInstance: fakeCharacteristicInstance
        )
    }

    private func fakePeripheral() -> Peripheral {
        let characteristic = FakeCharacteristic(
            uuid: fakeCharacteristicUuid,
            instance: fakeCharacteristicInstance,
            properties: [.read]
        )
        return FakePeripheral(
            id: fakePeripheralId,
            connectionState: .connected,
            services: [FakeService(uuid: fakeServiceUuid, characteristics: [characteristic])]
        )
    }
}
