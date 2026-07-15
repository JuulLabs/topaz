import Foundation

/// A live per-tab web session that can be explicitly torn down.
///
/// Abstracted as a protocol so the cache policy below is testable without
/// WebKit/UIKit collaborators.
@MainActor
protocol LiveTabSession: AnyObject {
    var tabIndex: Int { get }
    /// Ends the session: expected to disconnect any BLE peripherals, detach the
    /// script handler, and release the web view. Must be safe to call repeatedly.
    func teardown()
}

enum TabSessionLimits {
    /// Maximum number of tabs kept "hot" (live web view + Js context + BLE) at once.
    /// Beyond this, the least-recently-activated background session is torn down and
    /// its tab reverts to reload-on-revisit.
    static let maxLiveSessions = 4
}

/// Retention policy for live tab sessions.
///
/// Holds at most `maxLiveSessions` sessions. The most recently activated session is
/// "pinned" and is never chosen for least-recently-used eviction. Every eviction path
/// invokes the session's `teardown()` exactly once.
///
/// Lookup via `session(for:)` does not affect recency; only `insert(_:)` and
/// `markActive(_:)` refresh a session's LRU position.
@MainActor
final class TabSessionCache<Session: LiveTabSession> {
    private let maxLiveSessions: Int
    private var sessions: [Int: Session] = [:]
    /// Tab indexes ordered least-recently-activated first.
    private var lruOrder: [Int] = []
    /// The pinned tab: most recently activated, exempt from LRU eviction.
    private(set) var activeTabIndex: Int?

    init(maxLiveSessions: Int = TabSessionLimits.maxLiveSessions) {
        self.maxLiveSessions = maxLiveSessions
    }

    var count: Int {
        sessions.count
    }

    var liveTabIndexes: [Int] {
        lruOrder
    }

    func session(for tabIndex: Int) -> Session? {
        sessions[tabIndex]
    }

    /// Adds a session as the most recently used, evicting least-recently-activated
    /// background sessions as needed to respect the cap. Replacing a different session
    /// instance already cached for the same tab tears the old one down first.
    func insert(_ session: Session) {
        if let existing = sessions[session.tabIndex], existing !== session {
            existing.teardown()
        }
        sessions[session.tabIndex] = session
        refreshRecency(of: session.tabIndex)
        evictOverCap(protecting: session.tabIndex)
    }

    /// Pins the given tab (exempting it from LRU eviction) and refreshes its recency.
    /// The pin persists until another tab is activated or the pinned tab is evicted,
    /// so the last-viewed tab stays protected while e.g. the tab grid is showing.
    func markActive(_ tabIndex: Int) {
        guard sessions[tabIndex] != nil else { return }
        activeTabIndex = tabIndex
        refreshRecency(of: tabIndex)
    }

    /// Tears down and removes the session for the given tab. No-op for unknown tabs.
    func evict(_ tabIndex: Int) {
        guard let session = sessions.removeValue(forKey: tabIndex) else { return }
        lruOrder.removeAll { $0 == tabIndex }
        if activeTabIndex == tabIndex {
            activeTabIndex = nil
        }
        session.teardown()
    }

    /// Tears down every session except the pinned one (e.g. on memory warning).
    func evictAllExceptActive() {
        for tabIndex in lruOrder where tabIndex != activeTabIndex {
            evict(tabIndex)
        }
    }

    /// Tears down every session including the pinned one.
    func evictAll() {
        for tabIndex in lruOrder {
            evict(tabIndex)
        }
    }

    private func refreshRecency(of tabIndex: Int) {
        lruOrder.removeAll { $0 == tabIndex }
        lruOrder.append(tabIndex)
    }

    private func evictOverCap(protecting protectedTabIndex: Int) {
        while sessions.count > maxLiveSessions {
            let candidate = lruOrder.first { $0 != activeTabIndex && $0 != protectedTabIndex }
            guard let candidate else { return }
            evict(candidate)
        }
    }
}
