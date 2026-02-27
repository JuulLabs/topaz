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
                Gradient.Stop(color: Color.init(hex: "#CBD3EC")!.opacity(0), location: 0),
                Gradient.Stop(color: Color.init(hex: "#CBD3EC")!.opacity(0.8), location: 0.2),
                Gradient.Stop(color: Color.init(hex: "#CBD3EC")!.opacity(0.95), location: 1),
            ]
        } else {[
                Gradient.Stop(color: Color.init(hex: "#CBD3EC")!.opacity(0), location: 0),
                Gradient.Stop(color: Color.init(hex: "#CBD3EC")!.opacity(0.95), location: 1),
            ]
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            if model.isInSearchMode {
                SearchBarViewV2(model: model.searchBarModel)
                Button(action: {
                    model.isInSearchMode = false
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
                Button(action: {
                    model.isInSearchMode = true
                }, label: {
                    Text("nav mode placeholder")
                })
            }
        }
        .animation(.spring, value: model.isInSearchMode)
        .padding([.leading, .trailing], 36)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(
            LinearGradient(
                stops: backgroundGradientStops,
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
}

#Preview {
    NavBarViewV2(model: NavBarModel(tabManagementAction: {}, onFullscreenChanged: { _ in }))
}
