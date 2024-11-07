import SwiftUI

public enum MediaImage: String {
    case mainLogo = "topaz_logo"
}

extension Image {
    public init(media: MediaImage) {
        self.init(decorative: media.rawValue, bundle: Bundle.module)
    }
}
