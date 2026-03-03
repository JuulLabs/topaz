import SwiftUI
import UIHelpers
import Navigation

struct NavBarViewV2: View {

    let model: NavBarModel

    @State private var keyboardObserver = KeyboardObserver()

    private var keyboardPresent: Bool {
        keyboardObserver.frame != nil
    }

    // Because of how SwiftUI is drawing the background in regards to the keyboard, we need to change how much the gradient
    // stops when the keyboard is present vs when it's not.
    private var backgroundGradientStops: [Gradient.Stop] {
        if keyboardPresent {[
//                Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.navigationBackground.opacity(0), location: 0),
                Gradient.Stop(color: Color.navigationBackground.opacity(0.8), location: 0.2),
                Gradient.Stop(color: Color.navigationBackground.opacity(0.95), location: 1),
            ]
        } else {[
//            Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.navigationBackground.opacity(0), location: 0),
                Gradient.Stop(color: Color.navigationBackground.opacity(0.95), location: 1),
            ]
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            if model.navigator.isInSearchMode {
                SearchBarViewV2(model: model.searchBarModel)
                Button(action: {
                    model.navigator.isInSearchMode = false
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.iconDefault)
                        .font(.system(size: 18).weight(.light))
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.cellFillPrimary)
                        )
                })
            } else {
                NavIconStripV2(model: model)
            }
        }
        .animation(.spring, value: model.navigator.isInSearchMode)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
//        .blur(radius: 20.0)

        .background(
            LinearGradient(
                stops: backgroundGradientStops,
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
//            DEAR JUSTIN. YOU ARE TRYING TO MAKE THIS VIEW TRANSPARENT BUT WITH THE GRADIENT
//            .background(.thinMaterial)
            .edgesIgnoringSafeArea(.all)
        )
//        .border(Color.red)
//        .mask(
//            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black, Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
//                .edgesIgnoringSafeArea(.all)
//        )

//        .background(
//            Rectangle()
//                // Use a material for the translucent blur effect
//                .fill(.ultraThinMaterial)
//                // Apply a linear gradient as a mask
//                // The white/black areas define the visible/transparent parts of the mask
//                .background (
//                    LinearGradient(
//                        stops: backgroundGradientStops,
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                )
//                .mask(
//                    LinearGradient(
//                        stops: backgroundGradientStops,
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                )
//                .ignoresSafeArea()
//        )

    }
}

#Preview {
    NavBarViewV2(model: NavBarModel(tabManagementAction: {}, onFullscreenChanged: { _ in }))
}
