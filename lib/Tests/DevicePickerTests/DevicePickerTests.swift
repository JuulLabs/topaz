import Bluetooth
@testable import DevicePicker
import Foundation
import Testing

private func bigYield() async {
    try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 1000)
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DevicePickerTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")

    @Test
    func awaitSelection_whilePending_isSelectingIsTrue() async throws {
        let sut = DeviceSelector()
        async let pendingResult = await sut.awaitSelection()
        await bigYield()
        let isSelecting = sut.isSelecting
        sut.cancel()
        await _ = pendingResult
        #expect(isSelecting == true)
    }

    @Test
    func awaitSelection_whenFulfilled_isSelectingIsFalse() async throws {
        let sut = DeviceSelector()
        async let pendingResult = await sut.awaitSelection()
        await bigYield()
        sut.cancel()
        await _ = pendingResult
        let isSelecting = sut.isSelecting
        #expect(isSelecting == false)
    }

    @Test
    func cancel_whilePending_returnsCancelled() async throws {
        let sut = DeviceSelector()
        async let pendingResult = await sut.awaitSelection()
        await bigYield()
        sut.cancel()
        let result = await pendingResult
        switch result {
        case let .success(success):
            Issue.record("Unexpected result: \(success)")
        case let .failure(error):
            #expect(error == .cancelled)
        }
    }

    @Test
    func makeSelection_withInvalidId_returnsInvalidSelection() async throws {
        let sut = DeviceSelector()
        async let pendingResult = await sut.awaitSelection()
        await bigYield()
        sut.makeSelection(zeroUuid)
        let result = await pendingResult
        switch result {
        case let .success(success):
            Issue.record("Unexpected result: \(success)")
        case let .failure(error):
            #expect(error == .invalidSelection)
        }
    }

    @Test
    func makeSelection_withValidId_returnsMatchingDevice() async throws {
        let sut = DeviceSelector()
        async let pendingResult = await sut.awaitSelection()
        await bigYield()
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid)
        sut.showAdvertisement(peripheral: fake.eraseToAnyPeripheral(), advertisement: fake.fakeAd(rssi: 0))
        await bigYield()
        sut.makeSelection(fake._identifier)
        let result = await pendingResult
        switch result {
        case let .success(success):
            #expect(success.name == "bob")
        case let .failure(error):
            Issue.record("Unexpected result: \(error)")
        }
    }

    @Test
    func showAdvertisement_emitsAdvertisements() async throws {
        let sut = DeviceSelector()
        async let pendingResult = await sut.awaitSelection()
        await bigYield()
        let fake = FakePeripheral(name: "bob", identifier: zeroUuid)
        sut.showAdvertisement(peripheral: fake.eraseToAnyPeripheral(), advertisement: fake.fakeAd(rssi: 0))
        await bigYield()
        async let collected = await sut.advertisements.first(where: { !$0.isEmpty })!
        await bigYield()
        sut.cancel()
        await _ = pendingResult
        let ads = await collected
        #expect(ads.count == 1)
    }

}
