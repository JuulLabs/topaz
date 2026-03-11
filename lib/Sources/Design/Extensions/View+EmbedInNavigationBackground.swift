import SwiftUI

extension View {

    // Because of how SwiftUI is drawing the background in regards to the keyboard, we need to change how much the gradient
    // stops when the keyboard is present vs when it's not.
    private func backgroundGradientStops(keyboardPresent: Bool) -> [Gradient.Stop] {
        if keyboardPresent {[
                Gradient.Stop(color: Color.navigationBackground.opacity(0), location: 0),
                Gradient.Stop(color: Color.navigationBackground.opacity(0.8), location: 0.2),
                Gradient.Stop(color: Color.navigationBackground.opacity(0.95), location: 1),
            ]
        } else {[
                Gradient.Stop(color: Color.navigationBackground.opacity(0), location: 0),
                Gradient.Stop(color: Color.navigationBackground.opacity(0.6), location: 0.33),
                Gradient.Stop(color: Color.navigationBackground, location: 1),
            ]
        }
    }

    @ViewBuilder public func embedInNavigationBackground(keyboardPresent: Bool) -> some View {
        self
            .background(
                LinearGradient(
                    stops: backgroundGradientStops(keyboardPresent: keyboardPresent),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
    }
}
