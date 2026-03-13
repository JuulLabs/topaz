import SwiftUI

extension View {

    @ViewBuilder public func embedInRoundedRectangle(cornerRadius: CGFloat) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cellFillPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white, lineWidth: 0.25)
            )
    }
}
