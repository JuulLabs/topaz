import Foundation
@testable import Settings
import Testing

@MainActor
private final class WipeSpy {
    private var gate: CheckedContinuation<Void, Never>?
    private(set) var wipeStarted = false
    private(set) var events: [String] = []

    func beginWipe() async {
        wipeStarted = true
        await withCheckedContinuation { continuation in
            gate = continuation
        }
        events.append("wiped")
    }

    func recordReset() {
        events.append("reset")
    }

    func finishWipe() {
        gate?.resume()
        gate = nil
    }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SettingsModelTests {

    @Test
    func removeAllData_resetsSessionsOnlyAfterTheWipeCompletes() async throws {
        let model = SettingsModel()
        let spy = WipeSpy()
        model.removeAllWebData = { await spy.beginWipe() }
        model.onRemoveAllData = { spy.recordReset() }

        model.removeAllDataButtonTapped()
        #expect(model.presentClearCacheDialogue == false)
        while spy.wipeStarted == false {
            await Task.yield()
        }
        // The wipe is still in flight: sessions must not have been reset yet, or a
        // reloading page could read - and re-persist - the data being removed
        #expect(spy.events.isEmpty)

        spy.finishWipe()
        while spy.events.count < 2 {
            await Task.yield()
        }
        #expect(spy.events == ["wiped", "reset"])
    }
}
