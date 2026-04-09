import SwiftUI

extension View {

    public func embedInDismissableModal(
        trailingPadding: CGFloat,
        yOffset: CGFloat,
        onTapOutside: @escaping () -> Void
    ) -> some View {
        modifier(EmbeddedDissmissableModal(trailingPadding: trailingPadding, yOffset: yOffset, onTapOutside: onTapOutside))
    }
}

struct EmbeddedDissmissableModal: ViewModifier {

    let trailingPadding: CGFloat
    let yOffset: CGFloat
    let onTapOutside: () -> Void

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .contentShape(Rectangle()) // Ensures the entire area is tappable
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onTapOutside()
                }
            content
        }
        .padding(.trailing, trailingPadding)
        .offset(y: yOffset)
    }
}
