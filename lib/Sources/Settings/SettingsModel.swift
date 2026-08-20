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
    /// Called after the user removes all browsing data, so live sessions can be torn down.
    public var onRemoveAllData: () -> Void = {}

    /// Wipes the web data, returning only once the removal has finished. Injectable for tests.
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
            // Reset sessions only after the wipe completes. A page reloaded while the
            // removal is still in flight could read, and re-persist, "removed" data.
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
