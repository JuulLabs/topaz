import Foundation

/// Shared source of truth for which tab is currently displayed.
///
/// The app layer writes it whenever the displayed tab changes. Per-tab collaborators
/// read it, such as the device selector gate, which must behave differently for a
/// background tab. Nil means no tab is displayed, such as while the tab grid shows.
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
