import Design
import SwiftUI

struct PullDrawerView: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(media: .exitFullscreen)
                Text("Exit fullscreen")
                    .font(.dogpatch(.subheadline))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderActive, lineWidth: 1)
                .frame(minWidth: 68)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .background(Color.topaz600)
    }
}

#Preview {
    PullDrawerView { }
}
