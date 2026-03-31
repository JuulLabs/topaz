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
//        Button {
//            action()
//        } label: {
//            Image(systemName: systemImageName)
//                .symbolRenderingMode(.palette)
//                .foregroundStyle(Color.iconDefault, Color.cellFillPrimary)
//                .imageScale(.large)
//                .font(.largeTitle.weight(.light))
//        }
        Button(action: {
            // Action to perform when the button is tapped
            action()
        }) {
            Image(systemName: systemImageName) // Use an SF Symbol
//                .resizable()
//                .scaledToFit()
                .frame(width: 24, height: 24) // Set a fixed size
                .padding(16) // Add padding for the circular area
                .background(Color.cellFillPrimary) // Set the background color
                .foregroundColor(Color.iconDefault) // Set the icon color
                .clipShape(Circle()) // Clip the entire area into a circle
//                .border(Color.red)
        }
//        .frame(width: 40, height: 40) // Set a fixed size
//        .buttonStyle(.plain) // Use plain style to avoid default styling interference
    }
}

#Preview {
    CircleButton(systemImageName: "arrow.left") {

    }
}
