import Design
import SwiftUI

/// Geometry the preview thumbnails are captured against.
public enum TabPreviewMetrics {
    /// Point width of a grid cell at its smallest. Thumbnails are captured at this width
    /// and scaled up by the device's pixel ratio, so a cell never upscales its image by
    /// more than the grid stretches it.
    public static let width: CGFloat = TabCellLayout.minSize.width
    /// Width over height, matching the cell.
    public static let aspectRatio: CGFloat = 3.0 / 4.0
}

struct TabCellLayout: ViewModifier {
    // Sized to fit 2up on the smallest iPhone
    static let minSize = CGSize(width: 136, height: 184)

    func body(content: Content) -> some View {
        content
            .frame(minHeight: TabCellLayout.minSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(3/4, contentMode: .fill)
            .clipped()
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
