import Foundation

/// Shared source of truth for which tab is currently displayed.
///
/// Written by the app layer whenever the displayed tab changes and consulted by
/// per-tab collaborators (e.g. the device selector gate) that must behave differently
/// for background tabs. Nil means no tab is displayed (e.g. the tab grid is showing).
@MainActor
public final class ActiveTabState {
    public private(set) var activeTabIndex: Int?

    public init() {}

    public func setActiveTab(_ tabIndex: Int?) {
        activeTabIndex = tabIndex
    }

    public func isActive(tab: Int) -> Bool {
        activeTabIndex == tab
    }
}
