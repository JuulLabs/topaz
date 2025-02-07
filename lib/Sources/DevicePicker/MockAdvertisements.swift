#if targetEnvironment(simulator)
import Bluetooth
import Foundation

extension DeviceSelector {
    nonisolated public func injectMockAds() -> Task<Void, Never> {
        let peripherals = [
            "My neighbor's TV",
            "cOnNeCtEd TOoThBrUsH",
            "Rover the dog",
            "Barney",
            "Nuralink 0.0.6-beta",
            "35fc49b",
            "Really smart window",
            "Even smarter light bulb",
            "Batcomputer",
        ].map { FakePeripheral(id: UUID(), name: $0) }
        return Task {
            while !Task.isCancelled {
                let delay = UInt64.random(in: 1..<6)
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 2 * delay)
                let fake = peripherals.randomElement()!
                let rssi = Int.random(in: -90 ... -60)
                await showAdvertisement(peripheral: fake, advertisement: fake.fakeAdvertisement(rssi: rssi))
            }
        }
    }

    public func injectMockAdsAndStart() async {
        let injectionTask = injectMockAds()
        switch await awaitSelection() {
        case let .success(pick):
            print("Success: \(pick.name!)")
        case let .failure(error):
            print("Failure: \(error)")
        }
        injectionTask.cancel()
    }
}
#endif
