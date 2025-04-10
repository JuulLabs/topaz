import Observation
import SwiftUI

@MainActor
@Observable
public final class SettingsModel {
    var bluetoothEnabled: Bool = false {
        didSet { bluetoothPermissionsToggled() }
    }

    let searchEngineSelectorModel: SearchEngineSelectorModel

    public var dismiss: () -> Void  = {}
    public var shareItem: SharingUrl = .init()

    public var presentClearCacheDialogue: Bool = false
    public var presentPermissionsView: Bool = false

    public init(searchEngineSelectorModel: SearchEngineSelectorModel = .init()) {
        self.searchEngineSelectorModel = searchEngineSelectorModel
    }

    func doneButtonTapped() {
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

    func permissionsButtonTapped() {
        presentPermissionsView = true
    }

    private func bluetoothPermissionsToggled() {
    }
}
