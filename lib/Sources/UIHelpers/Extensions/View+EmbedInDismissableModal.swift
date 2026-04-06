import SwiftUI

extension View {

    @ViewBuilder public func embedInDismissableModal(
        onTapOutside: @escaping () -> Void,
        trailingPadding: CGFloat = 16,
        yOffset: CGFloat = -50
    ) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .contentShape(Rectangle()) // Ensures the entire area is tappable
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onTapOutside()
                }
            self
        }
        .padding(.trailing, trailingPadding)
        .offset(y: yOffset)
    }
}
