import SwiftUI

extension View {

    // Attempts to set the provided content as an iOS 26+ style "glass-y" bottom pinned
    // nav bar. If unavailable, will set the content as an approximation of that.
    @ViewBuilder func safeAreaBarIfAvailable(content: () -> some View) -> some View {
        if #available(iOS 26.0, *) {
            self.safeAreaBar(edge: .bottom) {
                content()
            }
        } else {
            VStack(spacing: 0) {
                self
                content()
                    .background(Color.white)
            }
        }
    }
}
