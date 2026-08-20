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

    @Test
    func insert_whenUnderTheCap_retainsEverySession() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3, 4])
        #expect(cache.count == 4)
        #expect(sessions.values.allSatisfy { $0.teardownCount == 0 })
    }

    @Test
    func insert_whenOverTheCap_evictsTheLeastRecentlyUsedSession() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3, 4, 5])
        #expect(cache.count == 4)
        #expect(cache.session(for: 1) == nil)
        #expect(sessions[1]?.teardownCount == 1)
        #expect([2, 3, 4, 5].allSatisfy { cache.session(for: $0) != nil })
    }

    @Test
    func insert_whenTheLeastRecentlyUsedTabIsActive_evictsTheOldestUnpinnedSessionInstead() {
        let (cache, sessions) = cacheWithSessions(cap: 2, tabs: [1, 2])
        cache.markActive(1)
        cache.insert(MockSession(tabIndex: 3))
        #expect(cache.session(for: 1) != nil)
        #expect(cache.session(for: 2) == nil)
        #expect(sessions[2]?.teardownCount == 1)
        #expect(cache.session(for: 3) != nil)
    }

    @Test
    func markActive_whenTheTabIsLive_refreshesItsRecency() {
        let (cache, _) = cacheWithSessions(cap: 3, tabs: [1, 2, 3])
        cache.markActive(1)
        cache.markActive(2)
        // LRU order is now 3, 1, 2 with the pin on 2, so inserting evicts 3
        cache.insert(MockSession(tabIndex: 4))
        #expect(cache.session(for: 3) == nil)
        #expect(cache.session(for: 1) != nil)
        #expect(cache.session(for: 2) != nil)
    }

    @Test
    func session_whenLookingUpALiveTab_doesNotRefreshItsRecency() {
        let (cache, _) = cacheWithSessions(cap: 3, tabs: [1, 2, 3])
        cache.markActive(3)
        _ = cache.session(for: 1)
        cache.insert(MockSession(tabIndex: 4))
        #expect(cache.session(for: 1) == nil)
        #expect(cache.session(for: 2) != nil)
    }

    @Test
    func markActive_whenTheTabHasNoLiveSession_leavesThePinUnset() {
        let (cache, _) = cacheWithSessions(cap: 3, tabs: [1])
        cache.markActive(99)
        #expect(cache.pinnedTabIndex == nil)
    }

    @Test
    func evict_whenCalledTwiceForTheSameTab_tearsDownTheSessionOnce() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2])
        cache.evict(1)
        cache.evict(1)
        #expect(sessions[1]?.teardownCount == 1)
        #expect(cache.count == 1)
    }

    @Test
    func evict_whenTheTabHasNoLiveSession_leavesTheCacheUnchanged() {
        let (cache, _) = cacheWithSessions(cap: 4, tabs: [1])
        cache.evict(42)
        #expect(cache.count == 1)
    }

    @Test
    func evict_whenTheTabIsActive_clearsThePin() {
        let (cache, _) = cacheWithSessions(cap: 4, tabs: [1, 2])
        cache.markActive(1)
        cache.evict(1)
        #expect(cache.pinnedTabIndex == nil)
    }

    @Test
    func evictAll_withASparedTab_keepsOnlyThatSession() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3, 4])
        cache.markActive(2)
        cache.evictAll(except: 2)
        #expect(cache.count == 1)
        #expect(cache.session(for: 2) != nil)
        #expect(sessions[2]?.teardownCount == 0)
        #expect([1, 3, 4].allSatisfy { sessions[$0]?.teardownCount == 1 })
    }

    @Test
    func evictAll_whenTheSparedTabIsNotThePinnedOne_sparesTheNamedTabAndEvictsThePinnedOne() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2])
        cache.markActive(1)
        cache.evictAll(except: 2)
        #expect(cache.session(for: 2) != nil)
        #expect(sessions[1]?.teardownCount == 1)
        #expect(sessions[2]?.teardownCount == 0)
    }

    @Test
    func evictAll_withNothingSpared_evictsEverySession() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2])
        cache.evictAll(except: nil)
        #expect(cache.count == 0)
        #expect(sessions.values.allSatisfy { $0.teardownCount == 1 })
    }

    @Test
    func evictAll_whenATabIsActive_tearsDownEverySessionAndClearsThePin() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1, 2, 3])
        cache.markActive(2)
        cache.evictAll()
        #expect(cache.count == 0)
        #expect(cache.pinnedTabIndex == nil)
        #expect(sessions.values.allSatisfy { $0.teardownCount == 1 })
    }

    @Test
    func insert_whenAnotherSessionIsCachedForTheTab_replacesItAndTearsDownTheOldOne() {
        let (cache, sessions) = cacheWithSessions(cap: 4, tabs: [1])
        let replacement = MockSession(tabIndex: 1)
        cache.insert(replacement)
        #expect(cache.count == 1)
        #expect(sessions[1]?.teardownCount == 1)
        #expect(replacement.teardownCount == 0)
        #expect(cache.session(for: 1) === replacement)
    }

    @Test
    func insert_whenTheSameSessionIsAlreadyCached_doesNotTearItDown() {
        let cache = TabSessionCache<MockSession>(maxLiveSessions: 4)
        let session = MockSession(tabIndex: 1)
        cache.insert(session)
        cache.insert(session)
        #expect(session.teardownCount == 0)
        #expect(cache.count == 1)
    }

    @Test
    func insert_whenTheCapIsFullOfProtectedTabs_keepsTheNewSessionAlive() {
        let (cache, sessions) = cacheWithSessions(cap: 1, tabs: [1])
        cache.markActive(1)
        let incoming = MockSession(tabIndex: 2)
        cache.insert(incoming)
        // Cap is 1 and both tabs are protected: 1 is pinned, 2 was just inserted.
        // The cache tolerates a temporary overshoot rather than evict either.
        #expect(cache.session(for: 2) === incoming)
        #expect(incoming.teardownCount == 0)
        // Activating the newcomer unpins tab 1, so the next insert evicts it
        cache.markActive(2)
        cache.insert(MockSession(tabIndex: 3))
        #expect(cache.session(for: 1) == nil)
        #expect(sessions[1]?.teardownCount == 1)
    }

    @Test
    func liveTabIndexes_whenATabIsActive_ordersTabsLeastRecentlyUsedFirst() {
        let (cache, _) = cacheWithSessions(cap: 4, tabs: [1, 2, 3])
        cache.markActive(1)
        #expect(cache.liveTabIndexes == [2, 3, 1])
    }
}
