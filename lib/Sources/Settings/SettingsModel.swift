import Observation
import SwiftUI

@MainActor
@Observable
public final class SettingsModel {
    var bluetoothEnabled: Bool = false {
        didSet { bluetoothPermissionsToggled() }
    }

    public var dismiss: () -> Void  = {}
    public var tabAction: () -> Void = {}

    public init() {
    }

    func doneButtonTapped() {
        dismiss()
    }

    func shareButtonTapped() {
    }

    func newTabButtonTapped() {
        tabAction()
    }

    func setDefaultHomeButtonTapped() {
    }

    func logsButtonTapped() {
    }

    func clearHistoryButtonTapped() {
    }

    func clearCacheButtonTapped() {
    }

    func privacyPolicyButtonTapped() {
    }

    private func bluetoothPermissionsToggled() {
    }
}
