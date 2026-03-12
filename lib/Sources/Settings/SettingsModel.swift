import Downloader
import Observation
import SwiftUI

@MainActor
@Observable
public final class SettingsModel {
    var bluetoothEnabled: Bool = false {
        didSet { bluetoothPermissionsToggled() }
    }

    let searchEngineSelectorModel: SearchEngineSelectorModel
    private let tabManagementAction: () -> Void

    public var dismiss: () -> Void  = {}
    public var shareItem: SharingUrl = .init()

    public var presentClearCacheDialogue: Bool = false
    public var presentDownloadsView: Bool = false
    public var presentPermissionsView: Bool = false

    public init(
        searchEngineSelectorModel: SearchEngineSelectorModel = .init(),
        tabManagementAction: @escaping () -> Void = {},
    ) {
        self.searchEngineSelectorModel = searchEngineSelectorModel
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
        cleanWebCache()
        presentClearCacheDialogue = false
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
        presentPermissionsView = true
    }

    public func tabManagementButtonTapped() {
        tabManagementAction()
    }

    private func bluetoothPermissionsToggled() {
    }
}
