import SwiftUI

public enum MediaImage: String {
    case mainLogo = "topaz_logo"

    case fullscreenIcon = "fullscreen_icon"
    case settingsIcon = "settings_icon"

}

extension Image {
    public init(media: MediaImage) {
        self.init(decorative: media.rawValue, bundle: Bundle.module)
    }
}
