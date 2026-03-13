import SwiftUI

struct ExitFullscreenButton: View {

    @State private var draggedLocation: CGPoint?

    let action: () -> Void
    private let startLocation = CGPoint(x: 20, y: 50)

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
        .position(self.draggedLocation ?? startLocation)
        .highPriorityGesture(
            DragGesture()
                .onChanged {
                    self.draggedLocation = CGPoint(x: startLocation.x, y: $0.location.y)
                }
        )
    }
}

#Preview {
    ExitFullscreenButton { }
}
