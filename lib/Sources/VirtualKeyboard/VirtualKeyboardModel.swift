import Observation
import SwiftUI

@MainActor
@Observable
public final class VirtualKeyboardModel {
    public var overlaysContent: Bool

    @ObservationIgnored
    public var onShow: () -> Void

    @ObservationIgnored
    public var onHide: () -> Void

    public init(
        overlaysContent: Bool = false,
        onShow: @escaping () -> Void = {},
        onHide: @escaping () -> Void = {}
    ) {
        self.overlaysContent = overlaysContent
        self.onShow = onShow
        self.onHide = onHide
    }
}
