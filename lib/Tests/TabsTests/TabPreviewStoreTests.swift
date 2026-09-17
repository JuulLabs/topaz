import Foundation
import Helpers
@testable import Tabs
import Testing

struct TabPreviewStoreTests {

    @Test
    func load_afterSaving_returnsTheStoredThumbnail() async {
        let store = TabPreviewStore(storage: InMemoryDataStorage())
        let tabID = UUID()
        await store.save(Data([0x01, 0x02]), for: tabID)
        #expect(await store.load(for: tabID) == Data([0x01, 0x02]))
    }

    @Test
    func load_forATabWithNoThumbnail_returnsNil() async {
        let store = TabPreviewStore(storage: InMemoryDataStorage())
        #expect(await store.load(for: UUID()) == nil)
    }

    @Test
    func remove_forOneTab_leavesTheOtherThumbnailsInPlace() async {
        let store = TabPreviewStore(storage: InMemoryDataStorage())
        let doomed = UUID()
        let survivor = UUID()
        await store.save(Data([0x01]), for: doomed)
        await store.save(Data([0x02]), for: survivor)
        await store.remove(for: doomed)
        #expect(await store.load(for: doomed) == nil)
        #expect(await store.load(for: survivor) == Data([0x02]))
    }

    @Test
    func removeAll_dropsEveryThumbnail() async {
        let store = TabPreviewStore(storage: InMemoryDataStorage())
        let first = UUID()
        let second = UUID()
        await store.save(Data([0x01]), for: first)
        await store.save(Data([0x02]), for: second)
        await store.removeAll()
        #expect(await store.load(for: first) == nil)
        #expect(await store.load(for: second) == nil)
    }
}
