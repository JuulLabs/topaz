import Foundation
import Observation

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
/// calls `teardown()` on the session exactly once.
///
/// Lookup with `session(for:)` does not affect recency. Only `insert(_:)` and
/// `markActive(_:)` refresh the LRU position of a session.
@MainActor
@Observable
final class TabSessionCache<Session: LiveTabSession> {
    @ObservationIgnored
    private let maxLiveSessions: Int
    private var sessions: [Int: Session] = [:]
    private var lruOrder: [Int] = []
    private(set) var pinnedTabIndex: Int?

    init(maxLiveSessions: Int = TabSessionLimits.maxLiveSessions) {
        self.maxLiveSessions = maxLiveSessions
    }

    var count: Int {
        sessions.count
    }

    var liveTabIndexes: [Int] {
        lruOrder
    }

    /// All live sessions, least-recently-activated first.
    var allSessions: [Session] {
        lruOrder.compactMap { sessions[$0] }
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

    /// Pins the given tab, which exempts it from LRU eviction, and refreshes its
    /// recency. The pin persists until another tab is activated or the pinned tab is
    /// evicted. The last-viewed tab therefore stays protected while the tab grid shows.
    func markActive(_ tabIndex: Int) {
        guard sessions[tabIndex] != nil else { return }
        pinnedTabIndex = tabIndex
        refreshRecency(of: tabIndex)
    }

    /// Tears down and removes the session for the given tab. No-op for unknown tabs.
    func evict(_ tabIndex: Int) {
        guard let session = sessions.removeValue(forKey: tabIndex) else { return }
        lruOrder.removeAll { $0 == tabIndex }
        if pinnedTabIndex == tabIndex {
            pinnedTabIndex = nil
        }
        session.teardown()
    }

    /// Tears down every session, optionally sparing one tab (e.g. the displayed one on
    /// a memory warning). Callers name the tab to spare rather than rely on the pin.
    /// The pin tracks the last *cached* activation, so it can lag the displayed tab.
    func evictAll(except sparedTabIndex: Int? = nil) {
        for tabIndex in lruOrder where tabIndex != sparedTabIndex {
            evict(tabIndex)
        }
    }

    private func refreshRecency(of tabIndex: Int) {
        lruOrder.removeAll { $0 == tabIndex }
        lruOrder.append(tabIndex)
    }

    private func evictOverCap(protecting protectedTabIndex: Int) {
        while sessions.count > maxLiveSessions {
            let candidate = lruOrder.first { $0 != pinnedTabIndex && $0 != protectedTabIndex }
            guard let candidate else { return }
            evict(candidate)
        }
    }
}
