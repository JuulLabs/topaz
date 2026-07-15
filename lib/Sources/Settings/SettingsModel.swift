import Downloader
import Permissions
import Observation
import SwiftUI

@MainActor
@Observable
public final class SettingsModel {
    var bluetoothEnabled: Bool = false {
        didSet { bluetoothPermissionsToggled() }
    }

    let searchEngineSelectorModel: SearchEngineSelectorModel
    var permissionsModel: PermissionsModel
    private let tabManagementAction: () -> Void

    public var dismiss: () -> Void  = {}
    public var shareItem: SharingUrl = .init()
    /// Invoked after the user removes all browsing data so live web sessions can be
    /// torn down; no page should keep in-memory state whose backing storage was wiped.
    public var onRemoveAllData: () -> Void = {}

    /// Performs the actual web data wipe; injectable for tests. Must complete only
    /// once the removal has finished so dependent work can be sequenced after it.
    var removeAllWebData: @MainActor () async -> Void = { await cleanWebCache() }

    public var presentClearCacheDialogue: Bool = false
    public var presentDownloadsView: Bool = false

    public init(
        searchEngineSelectorModel: SearchEngineSelectorModel = .init(),
        permissionsModel: PermissionsModel = .shared,
        tabManagementAction: @escaping () -> Void = {},
    ) {
        self.searchEngineSelectorModel = searchEngineSelectorModel
        self.permissionsModel = permissionsModel
        self.tabManagementAction = tabManagementAction
    }

    // TODO: Remove after migrating SettingsViewV2 to SettingsView
    func doneButtonTapped() {
        dismiss()
    }

    func onTapOutside() {
        dismiss()
    }

    func setDefaultHomeButtonTapped() {
    }

    func clearHistoryButtonTapped() {
    }

    func clearCacheButtonTapped() {
        presentClearCacheDialogue = true
    }

    func removeAllDataButtonTapped() {
        presentClearCacheDialogue = false
        Task {
            // Reset sessions only after the wipe completes: a page reloaded while the
            // removal is still in flight could read - and re-persist - "removed" data
            await removeAllWebData()
            onRemoveAllData()
        }
    }

    func privacyPolicyButtonTapped() {
    }

    var isDownloadsDisabled: Bool {
        Downloads.shared.isEmpty
    }

    func downloadsButtonTapped() {
        presentDownloadsView = true
    }

    func permissionsButtonTapped() {
        permissionsModel.presentPermissionsView = true
    }

    public func tabManagementButtonTapped() {
        tabManagementAction()
    }

    private func bluetoothPermissionsToggled() {
    }
}
