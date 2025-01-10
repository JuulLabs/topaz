import Design
import SwiftUI

struct TabCellLayout: ViewModifier {
    // Sized to fit 2up on the smallest iPhone
    static let minSize = CGSize(width: 136, height: 184)

    func body(content: Content) -> some View {
        content
            .frame(minHeight: TabCellLayout.minSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(3/4, contentMode: .fill)
            .cornerRadius(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 0.25)
                    .stroke(Color.borderActive, lineWidth: 0.25)
                    .fill(Color.canvasHighContrast)
            }
    }
}

extension View {
    func tabCellLayout() -> some View {
        modifier(TabCellLayout())
    }
}
