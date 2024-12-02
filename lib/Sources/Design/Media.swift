import SwiftUI

public enum MediaImage: String {
    case mainLogo = "topaz_logo"

    case fullscreenIcon = "fullscreen_icon"
    case settingsIcon = "settings_icon"

    case signalNone = "signal_none"
    case signalOne = "signal_one"
    case signalThree = "signal_three"
    case signalTwo = "signal_two"
}

extension Image {
    public init(media: MediaImage) {
        self.init(decorative: media.rawValue, bundle: Bundle.module)
    }
}
