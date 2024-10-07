import SwiftUI

public struct AppContentView: View {

    public init () {}

    public var body: some View {
        VStack {
            Text("Topaz")
                .font(.title)
            Image(systemName: "rhombus")
                .imageScale(.large)
        }
        .padding()
    }
}

#Preview {
    AppContentView()
}
