import Design
import SwiftUI

extension View {

    @ViewBuilder public func embedInRoundedRectangle(
        cornerRadius: CGFloat,
        backgroundColor: Color = Color.cellFillPrimary,
        opacity: CGFloat = 1.0,
        borderStroke: CGFloat = 0.25
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor.opacity(opacity))
                    .stroke(Color.white, lineWidth: borderStroke)
            )
    }
}
