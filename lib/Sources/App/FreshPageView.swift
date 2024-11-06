import Design
import SwiftUI
import UIHelpers

struct FreshPageView: View {
    let model: FreshPageModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                FreshPageHeaderView()
                    .position(headerPosition(in: geometry))
                if model.isLoading {
                    ProgressView()
                        .controlSize(.extraLarge)
                        .tint(.white)
                } else {
                    SearchBarView(model: model.searchBarModel)
                        .padding(.horizontal, 24)
                }
            }
            .background(Color.topaz600)
            .onTapGesture {
                // Tap outside to dismiss the keyboard
                resignFirstResponder()
            }
        }
    }

    private func headerPosition(in geometry: GeometryProxy) -> CGPoint {
        let frame = geometry.frame(in: .local)
        let xPos = frame.midX
        let yPos = floor(frame.height / 4) // Centered in the top half
        print("height = \(frame.height) center = \(frame.midY) quart = \(yPos)")
        return CGPointMake(xPos, yPos)
    }
}

#Preview("New") {
    let model = FreshPageModel(searchBarModel: SearchBarModel())
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}

#Preview("Loading") {
    let model = FreshPageModel(searchBarModel: SearchBarModel(), isLoading: true)
    FreshPageView(model: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
