import Observation
import SwiftUI

@MainActor
@Observable
public final class NavBarModel {

    var backButtonDisabled: Bool = true
    var forwardButtonDisabled: Bool = true
    var fullscreenButtonDisabled: Bool = false

    init() {
    }

    func backButtonTapped() {
    }

    func forwardButtonTapped() {
    }

    func fullscreenButtonTapped() {
    }

    func settingsButtonTapped() {
    }
}
