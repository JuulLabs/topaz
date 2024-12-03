import Observation
import SwiftUI

@MainActor
@Observable
public final class SettingsModel {
    var bluetoothEnabled: Bool = false {
        didSet { bluetoothPermissionsToggled() }
    }

    public init() {
    }

    func shareButtonTapped() {
    }

    func newTabButtonTapped() {
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
