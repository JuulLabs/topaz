@testable import App
import Foundation
import Helpers
import Tabs
import Testing
import WebView

@MainActor
private final class FakePage: PagePreviewCapturing {
    private(set) var captureCount = 0
    var data: Data?

    init(data: Data? = Data([0xAA])) {
        self.data = data
    }

    func capturePreview(format: PagePreviewFormat) async -> Data? {
        captureCount += 1
        return data
    }
}

@MainActor
struct TabPreviewCoordinatorTests {

    private func makeCoordinator(
        storage: InMemoryDataStorage = InMemoryDataStorage(),
        debounceInterval: Duration = .milliseconds(50)
    ) -> (TabPreviewCoordinator, TabPreviewStore) {
        let store = TabPreviewStore(storage: storage)
        let coordinator = TabPreviewCoordinator(
            store: store,
            format: PagePreviewFormat(width: 136, aspectRatio: 3.0 / 4.0),
            debounceInterval: debounceInterval
        )
        return (coordinator, store)
    }

    private func settle() async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(20))
    }

    @Test
    func pageDidLoad_forATabWithNoThumbnail_capturesImmediately() async {
        let (coordinator, store) = makeCoordinator()
        let page = FakePage()
        let tabID = UUID()
        coordinator.pageDidLoad(tabID: tabID, page: page)
        await settle()
        #expect(page.captureCount == 1)
        #expect(await store.load(for: tabID) == Data([0xAA]))
    }

    @Test
    func pageDidLoad_afterAThumbnailExists_waitsOutTheDebounceInterval() async {
        let (coordinator, _) = makeCoordinator()
        let page = FakePage()
        let tabID = UUID()
        coordinator.pageDidLoad(tabID: tabID, page: page)
        await settle()
        coordinator.pageDidLoad(tabID: tabID, page: page)
        coordinator.pageDidLoad(tabID: tabID, page: page)
        coordinator.pageDidLoad(tabID: tabID, page: page)
        #expect(page.captureCount == 1)
        try? await Task.sleep(for: .milliseconds(200))
        // The burst collapses onto a single trailing capture
        #expect(page.captureCount == 2)
    }

    @Test
    func captureNow_withADebouncedCapturePending_capturesOnceAndCancelsTheTimer() async {
        let (coordinator, _) = makeCoordinator()
        let page = FakePage()
        let tabID = UUID()
        coordinator.pageDidLoad(tabID: tabID, page: page)
        await settle()
        coordinator.pageDidLoad(tabID: tabID, page: page)
        coordinator.captureNow(tabID: tabID, page: page)
        await settle()
        #expect(page.captureCount == 2)
        try? await Task.sleep(for: .milliseconds(200))
        #expect(page.captureCount == 2)
    }

    @Test
    func pageDidLoad_forOneBusyTab_doesNotDelayAnotherTabsFirstCapture() async {
        let (coordinator, _) = makeCoordinator()
        let busy = FakePage()
        let quiet = FakePage()
        let busyID = UUID()
        coordinator.pageDidLoad(tabID: busyID, page: busy)
        await settle()
        coordinator.pageDidLoad(tabID: busyID, page: busy)
        coordinator.pageDidLoad(tabID: UUID(), page: quiet)
        await settle()
        #expect(quiet.captureCount == 1)
    }

    @Test
    func pageDidLoad_whenTheCaptureFails_keepsThePreviousThumbnail() async {
        let (coordinator, store) = makeCoordinator()
        let page = FakePage()
        let tabID = UUID()
        coordinator.pageDidLoad(tabID: tabID, page: page)
        await settle()
        page.data = nil
        coordinator.captureNow(tabID: tabID, page: page)
        await settle()
        #expect(await store.load(for: tabID) == Data([0xAA]))
    }

    @Test
    func removePreview_forADeletedTab_deletesItsThumbnail() async {
        let (coordinator, store) = makeCoordinator()
        let page = FakePage()
        let tabID = UUID()
        coordinator.pageDidLoad(tabID: tabID, page: page)
        await settle()
        coordinator.removePreview(for: tabID)
        await settle()
        #expect(await store.load(for: tabID) == nil)
    }

    @Test
    func removeAllPreviews_afterDataRemoval_deletesEveryThumbnail() async {
        let (coordinator, store) = makeCoordinator()
        let first = UUID()
        let second = UUID()
        coordinator.pageDidLoad(tabID: first, page: FakePage())
        coordinator.pageDidLoad(tabID: second, page: FakePage())
        await settle()
        coordinator.removeAllPreviews()
        await settle()
        #expect(await store.load(for: first) == nil)
        #expect(await store.load(for: second) == nil)
    }

    @Test
    func onPreviewStored_afterACaptureLands_reportsTheTab() async {
        let (coordinator, _) = makeCoordinator()
        var stored: [UUID] = []
        coordinator.onPreviewStored = { stored.append($0) }
        let tabID = UUID()
        coordinator.pageDidLoad(tabID: tabID, page: FakePage())
        await settle()
        #expect(stored == [tabID])
    }
}
