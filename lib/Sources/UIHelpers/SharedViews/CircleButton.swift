import SwiftUI

public struct CircleButton: View {

    let systemImageName: String
    let action: () -> Void

    public init(
        systemImageName: String,
        action: @escaping () -> Void
    ) {
        self.systemImageName = systemImageName
        self.action = action
    }

    public var body: some View {
        Button(action: {
            action()
        }, label: {
            Image(systemName: systemImageName)
                .frame(width: 24, height: 24)
                .padding(16)
                .background(Color.cellFillPrimary)
                .foregroundColor(Color.iconDefault)
                .clipShape(Circle())
        })
    }
}

#Preview {
    CircleButton(systemImageName: "arrow.left") {}
}
