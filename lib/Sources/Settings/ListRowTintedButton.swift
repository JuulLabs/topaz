import Design
import SwiftUI

/**
 Mimics the default behavior of a button in a List but with a colored background.
 The listRowBackground modifier annihilates the default button behavior so we do
 our best to restore it.
 */
struct ListRowTintedButton: ViewModifier {
    @State private var isPressed = false
    let color: Color
    let activeColor: Color
    let action: @MainActor () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(.rect) // Allow touches everywhere
            ._onButtonGesture(pressing: { isPressed = $0 }, perform: action)
            .listRowBackground(isPressed ? activeColor : color)
    }
}

extension View {
    func listRowTintedButton(
        color: Color = .accentColor,
        activeColor: Color? = nil,
        action: @MainActor @escaping () -> Void
    ) -> some View {
        modifier(
            ListRowTintedButton(
                color: color,
                activeColor: activeColor ?? color.shaded(level: .two),
                action: action
            )
        )
    }
}
