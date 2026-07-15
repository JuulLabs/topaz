import Testing
@testable import App

@MainActor
private final class MockSession: LiveTabSession {
    let tabIndex: Int
    private(set) var teardownCount = 0

    init(tabIndex: Int) {
        self.tabIndex = tabIndex
    }

    func teardown() {
        teardownCount += 1
    }
}

@MainActor
struct TabSessionCacheTests {

    private func cacheWithSessions(cap: Int, tabs: [Int]) -> (TabSessionCache<MockSession>, [Int: MockSession]) {
        let cache = TabSessionCache<MockSession>(maxLiveSessions: cap)
        var sessions: [Int: MockSession] = [:]
        for tab in tabs {
            let session = MockSession(tabIndex: tab)
            sessions[tab] = session
            cache.insert(session)
        }
        return (cache, sessions)
    }

    @Test func insertUnderCapRetainsAllSessions() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3, 4])
        #expect(cache.count == 4)
        #expect(sessions.values.allSatisfy { $0.teardownCount == 0 })
    }

    @Test func insertBeyondCapEvictsLeastRecentlyUsed() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3, 4, 5])
        #expect(cache.count == 4)
        #expect(cache.session(for: 1) == nil)
        #expect(sessions[1]?.teardownCount == 1)
        #expect([2, 3, 4, 5].allSatisfy { cache.session(for: $0) != nil })
    }

    @Test func activeTabIsNeverEvictedByCap() {
        let (cache, sessions) = cacheWithSessions(cap: 2, tabs: [1, 2])
        cache.markActive(1)
        cache.insert(MockSession(tabIndex: 3))
        // Tab 2 is the LRU candidate because tab 1 is pinned despite being older
        #expect(cache.session(for: 1) != nil)
        #expect(cache.session(for: 2) == nil)
        #expect(sessions[2]?.teardownCount == 1)
        #expect(cache.session(for: 3) != nil)
    }

    @Test func markActiveRefreshesRecency() {
        let (cache, _) = cacheWithSessions(cap: 3, tabs: [1, 2, 3])
        cache.markActive(1)
        cache.markActive(2)
        // LRU order is now 3, 1, 2 and pin is on 2 → inserting evicts 3
        cache.insert(MockSession(tabIndex: 4))
        #expect(cache.session(for: 3) == nil)
        #expect(cache.session(for: 1) != nil)
        #expect(cache.session(for: 2) != nil)
    }

    @Test func lookupDoesNotRefreshRecency() {
        let (cache, _) = cacheWithSessions(cap: 3, tabs: [1, 2, 3])
        cache.markActive(3)
        _ = cache.session(for: 1)
        cache.insert(MockSession(tabIndex: 4))
        // Tab 1 is still the LRU despite the lookup
        #expect(cache.session(for: 1) == nil)
        #expect(cache.session(for: 2) != nil)
    }

    @Test func markActiveForUnknownTabIsIgnored() {
        let (cache, _) = cacheWithSessions(cap: 3, tabs: [1])
        cache.markActive(99)
        #expect(cache.pinnedTabIndex == nil)
    }

    @Test func evictTearsDownExactlyOnce() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2])
        cache.evict(1)
        cache.evict(1)
        #expect(sessions[1]?.teardownCount == 1)
        #expect(cache.count == 1)
    }

    @Test func evictUnknownTabIsNoOp() {
        let (cache, _) = cacheWithSessions(cap: 4, tabs: [1])
        cache.evict(42)
        #expect(cache.count == 1)
    }

    @Test func evictActiveTabClearsPin() {
        let (cache, _) = cacheWithSessions(cap: 4, tabs: [1, 2])
        cache.markActive(1)
        cache.evict(1)
        #expect(cache.pinnedTabIndex == nil)
    }

    @Test func evictAllExceptActiveKeepsOnlyPinnedSession() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3, 4])
        cache.markActive(2)
        cache.evictAllExceptActive()
        #expect(cache.count == 1)
        #expect(cache.session(for: 2) != nil)
        #expect(sessions[2]?.teardownCount == 0)
        #expect([1, 3, 4].allSatisfy { sessions[$0]?.teardownCount == 1 })
    }

    @Test func evictAllExceptActiveWithNoPinEvictsEverything() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2])
        cache.evictAllExceptActive()
        #expect(cache.count == 0)
        #expect(sessions.values.allSatisfy { $0.teardownCount == 1 })
    }

    @Test func evictAllTearsDownEverythingIncludingActive() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3])
        cache.markActive(2)
        cache.evictAll()
        #expect(cache.count == 0)
        #expect(cache.pinnedTabIndex == nil)
        #expect(sessions.values.allSatisfy { $0.teardownCount == 1 })
    }

    @Test func reinsertingSameTabReplacesAndTearsDownOldSession() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1])
        let replacement = MockSession(tabIndex: 1)
        cache.insert(replacement)
        #expect(cache.count == 1)
        #expect(sessions[1]?.teardownCount == 1)
        #expect(replacement.teardownCount == 0)
        #expect(cache.session(for: 1) === replacement)
    }

    @Test func reinsertingIdenticalSessionDoesNotTearItDown() {
        let cache = TabSessionCache<MockSession>(maxLiveSessions: 4)
        let session = MockSession(tabIndex: 1)
        cache.insert(session)
        cache.insert(session)
        #expect(session.teardownCount == 0)
        #expect(cache.count == 1)
    }

    @Test func newlyInsertedSessionIsProtectedFromItsOwnEviction() {
        let (cache, sessions) = cacheWithSessions(cap: 1, tabs: [1])
        cache.markActive(1)
        let incoming = MockSession(tabIndex: 2)
        cache.insert(incoming)
        // Cap is 1 and both tabs are protected (1 pinned, 2 just inserted):
        // the cache tolerates a temporary overshoot rather than evicting either
        #expect(cache.session(for: 2) === incoming)
        #expect(incoming.teardownCount == 0)
        // Activating the newcomer unpins tab 1; the next insert evicts it
        cache.markActive(2)
        cache.insert(MockSession(tabIndex: 3))
        #expect(cache.session(for: 1) == nil)
        #expect(sessions[1]?.teardownCount == 1)
    }

    @Test func liveTabIndexesReportsLruOrder() {
        let (cache, _) = cacheWithSessions(cap: 4, tabs: [1, 2, 3])
        cache.markActive(1)
        #expect(cache.liveTabIndexes == [2, 3, 1])
    }
}
