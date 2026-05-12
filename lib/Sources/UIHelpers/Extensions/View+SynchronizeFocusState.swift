import SwiftUI

public extension View {
    /// Synchronize the view focus field state with the model focus field state.
    /// Necessary because the @FocusState property wrapper can only be held by a view due to DynamicProperty conformance.
    func synchronize<Value: Equatable>(
        _ model: Binding<Value>,
        _ view: FocusState<Value>.Binding
    ) -> some View {
        self
            .onAppear {
                view.wrappedValue = model.wrappedValue
                print("batman: \(view.wrappedValue)")
            }
            .onChange(of: model.wrappedValue) {
                view.wrappedValue = model.wrappedValue
                print("batman: \(view.wrappedValue)")
            }
            .onChange(of: view.wrappedValue) {
                model.wrappedValue = view.wrappedValue
                print("batman: \(view.wrappedValue)")
            }
    }
}
