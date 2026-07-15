import Bluetooth
@testable import DevicePicker
import Foundation
import TestHelpers
import Testing

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct TabGatedDeviceSelectorTests {

    private let zeroUuid: UUID! = UUID(uuidString: "00000000-0000-0000-0000-000000000000")

    @Test
    func awaitSelection_whenTabIsActive_forwardsToTheWrappedSelector() async throws {
        let inner = DeviceSelector()
        let activeTabState = ActiveTabState()
        activeTabState.setActiveTab(3)
        let sut = TabGatedDeviceSelector(tab: 3, activeTabState: activeTabState, wrapping: inner)
        async let pendingResult = await sut.awaitSelection()
        await Task.bigYield()
        #expect(inner.isSelecting == true)
        let fake = FakePeripheral(id: zeroUuid, name: "bob")
        await sut.showAdvertisement(peripheral: fake, advertisement: fake.fakeAdvertisement(rssi: 0))
        await Task.bigYield()
        await sut.makeSelection(fake.id)
        let result = await pendingResult
        switch result {
        case let .success(success):
            #expect(success.name == "bob")
        case let .failure(error):
            Issue.record("Unexpected result: \(error)")
        }
    }

    @Test
    func awaitSelection_whenAnotherTabIsActive_failsFastWithPageNotVisible() async throws {
        let inner = DeviceSelector()
        let activeTabState = ActiveTabState()
        activeTabState.setActiveTab(1)
        let sut = TabGatedDeviceSelector(tab: 2, activeTabState: activeTabState, wrapping: inner)
        let result = await sut.awaitSelection()
        switch result {
        case let .success(success):
            Issue.record("Unexpected result: \(success)")
        case let .failure(error):
            #expect(error == .pageNotVisible)
        }
        // The wrapped selector was never engaged: no picker UI presented
        #expect(inner.isSelecting == false)
    }

    @Test
    func awaitSelection_whenNoTabIsDisplayed_failsFastWithPageNotVisible() async throws {
        let inner = DeviceSelector()
        let activeTabState = ActiveTabState()
        activeTabState.setActiveTab(nil)
        let sut = TabGatedDeviceSelector(tab: 2, activeTabState: activeTabState, wrapping: inner)
        let result = await sut.awaitSelection()
        switch result {
        case let .success(success):
            Issue.record("Unexpected result: \(success)")
        case let .failure(error):
            #expect(error == .pageNotVisible)
        }
        #expect(inner.isSelecting == false)
    }

    @Test
    func showAdvertisement_fromABackgroundTab_neverReachesThePicker() async throws {
        let inner = DeviceSelector()
        let activeTabState = ActiveTabState()
        activeTabState.setActiveTab(1)
        let activeTab = TabGatedDeviceSelector(tab: 1, activeTabState: activeTabState, wrapping: inner)
        let backgroundTab = TabGatedDeviceSelector(tab: 2, activeTabState: activeTabState, wrapping: inner)

        async let pendingResult = await activeTab.awaitSelection()
        await Task.bigYield()
        #expect(inner.isSelecting == true)
        // A background tab's transient scan (before its own awaitSelection is
        // rejected) must not inject its advertisements into the active picker
        let intruder = FakePeripheral(id: zeroUuid, name: "intruder")
        await backgroundTab.showAdvertisement(peripheral: intruder, advertisement: intruder.fakeAdvertisement(rssi: 0))
        await Task.bigYield()
        await activeTab.cancel()
        let result = await pendingResult
        switch result {
        case let .success(success):
            Issue.record("Unexpected result: \(success)")
        case let .failure(error):
            // presentedItems is empty: the intruder's advertisement was dropped
            #expect(error == .cancelled(presentedItems: []))
        }
    }

    @Test
    func awaitSelection_fromABackgroundTab_doesNotDisturbTheActiveTabsSelection() async throws {
        let inner = DeviceSelector()
        let activeTabState = ActiveTabState()
        activeTabState.setActiveTab(1)
        let activeTab = TabGatedDeviceSelector(tab: 1, activeTabState: activeTabState, wrapping: inner)
        let backgroundTab = TabGatedDeviceSelector(tab: 2, activeTabState: activeTabState, wrapping: inner)

        async let pendingResult = await activeTab.awaitSelection()
        await Task.bigYield()
        let rejected = await backgroundTab.awaitSelection()
        switch rejected {
        case let .success(success):
            Issue.record("Unexpected result: \(success)")
        case let .failure(error):
            #expect(error == .pageNotVisible)
        }
        // The active tab's selection is still pending and resolvable
        #expect(inner.isSelecting == true)
        let fake = FakePeripheral(id: zeroUuid, name: "bob")
        await activeTab.showAdvertisement(peripheral: fake, advertisement: fake.fakeAdvertisement(rssi: 0))
        await Task.bigYield()
        await activeTab.makeSelection(fake.id)
        let result = await pendingResult
        switch result {
        case let .success(success):
            #expect(success.name == "bob")
        case let .failure(error):
            Issue.record("Unexpected result: \(error)")
        }
    }
}
