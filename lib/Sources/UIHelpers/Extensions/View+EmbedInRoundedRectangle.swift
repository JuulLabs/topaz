import SwiftUI

extension View {

    @ViewBuilder public func embedInRoundedRectangle(
        cornerRadius: CGFloat,
        opacity: CGFloat = 1.0,
        borderStroke: CGFloat = 0.25
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cellFillPrimary.opacity(opacity))
                    .stroke(Color.white, lineWidth: borderStroke)
            )
    }
}
