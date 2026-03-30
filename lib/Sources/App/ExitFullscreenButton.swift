import SwiftUI

struct ExitFullscreenButton: View {

    @State private var draggedLocation: CGPoint?

    let action: () -> Void
    private let startLocation = CGPoint(x: 20, y: 50)
    private let maxY = UIScreen.main.bounds.height - 120

    var body: some View {
        Button {
            action()
        } label: {
                Image(media: .exitFullscreen)
                    .font(.system(size: 32))
                    .padding()
                    .padding(.leading, 10)
                    .embedInRoundedRectangle(cornerRadius: 24, opacity: 0.75, borderStroke: 1.0)
        }
        .animation(.default, value: draggedLocation)
        .position(draggedLocation ?? startLocation)
        .highPriorityGesture(
            DragGesture()
                .onChanged {
                    draggedLocation = CGPoint(x: startLocation.x, y: $0.location.y.clamped(to: 0...maxY))
                }
        )
    }
}

#Preview {
    ExitFullscreenButton { }
}
