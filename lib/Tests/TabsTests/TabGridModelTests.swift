import Foundation
@testable import Tabs
import Testing

@MainActor
struct TabGridModelTests {

    private func modelWithUrls(_ urls: [String]) -> TabGridModel {
        TabGridModel(urls: urls.map { URL(string: $0)! })
    }

    @Test func deleteButtonTapped_removesTheTab() {
        let model = modelWithUrls(["https://one.example", "https://two.example"])
        let doomed = model.tabCells[0]
        model.deleteButtonTapped(tab: doomed)
        #expect(model.findTab(for: doomed.index) == nil)
        #expect(model.tabCells.count == 1)
    }

    @Test func deleteButtonTapped_firesOnTabDeletedWithTheTabIndex() {
        let model = modelWithUrls(["https://one.example", "https://two.example"])
        var deletedIndexes: [Int] = []
        model.onTabDeleted = { deletedIndexes.append($0) }
        model.deleteButtonTapped(tab: model.tabCells[1])
        #expect(deletedIndexes == [2])
    }

    @Test func deleteButtonTapped_leavesOtherTabsUntouched() {
        let model = modelWithUrls(["https://one.example", "https://two.example", "https://three.example"])
        model.deleteButtonTapped(tab: model.tabCells[1])
        #expect(model.urls.map(\.absoluteString) == ["https://one.example", "https://three.example"])
    }

    @Test func findOrCreateTab_reusesTheExistingTabForAKnownUrl() {
        let model = modelWithUrls(["https://one.example", "https://two.example"])
        let tab = model.findOrCreateTab(for: URL(string: "https://two.example")!)
        #expect(tab.index == 2)
        #expect(model.tabCells.count == 2)
    }

    @Test func findOrCreateTab_createsANewTabForAnUnknownUrl() {
        let model = modelWithUrls(["https://one.example"])
        let tab = model.findOrCreateTab(for: URL(string: "https://two.example")!)
        #expect(tab.index == 2)
        #expect(model.tabCells.count == 2)
    }

    @Test func update_createsAGridCellAtTheGivenIndex() {
        let model = modelWithUrls([])
        #expect(model.isEmpty)
        model.update(url: URL(string: "https://one.example")!, at: 7)
        #expect(model.findTab(for: 7)?.url.absoluteString == "https://one.example")
    }

    @Test func deletingAMiddleTabDoesNotRecycleItsIndex() {
        let model = modelWithUrls(["https://one.example", "https://two.example"])
        model.deleteButtonTapped(tab: model.tabCells[0])
        let tab = model.findOrCreateTab(for: URL(string: "https://three.example")!)
        // nextIndex derives from the max live index, so the deleted index 1 is not
        // recycled while tab 2 still exists
        #expect(tab.index == 3)
        #expect(model.findTab(for: 1) == nil)
    }

    @Test func deletingTheHighestTabAllowsItsIndexToBeReused() {
        let model = modelWithUrls(["https://one.example", "https://two.example"])
        model.deleteButtonTapped(tab: model.tabCells[1])
        let tab = model.findOrCreateTab(for: URL(string: "https://three.example")!)
        // Index reuse is why deletion must tear down the old session immediately:
        // a new tab at a recycled index must never inherit a stale live session
        #expect(tab.index == 2)
        #expect(model.findTab(for: 2)?.url.absoluteString == "https://three.example")
    }
}
