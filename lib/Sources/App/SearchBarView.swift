import Design
import DevicePicker
import Observation
import SwiftUI
import UIHelpers

struct SearchBarView: View {
    @Bindable var model: SearchBarModel
    @FocusState private var focusedField: SearchBarModel.FocusedField?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.ultraLight))
                .foregroundStyle(Color.steel600)
            TextField("Paste or enter website address", text: $model.searchString)
                .font(.dogpatch(.subheadline))
                .foregroundStyle(Color.steel600)
                .focused($focusedField, equals: .searchBar)
                .keyboardType(.default)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    model.didSubmitSearchString()
                }
        }
        .padding(12)
        .background(.white)
        .cornerRadius(24)
        .frame(maxWidth: .infinity, minHeight: 48)
        .synchronize($model.focusedField, $focusedField)
    }
}

fileprivate extension View {
    /// Synchronize the view focus field state with the model focus field state.
    /// Necessary because the @FocusState property wrapper can only be held by a view due to DynamicProperty conformance.
    func synchronize<Value: Equatable>(
        _ model: Binding<Value>,
        _ view: FocusState<Value>.Binding
    ) -> some View {
        self
            .onAppear { view.wrappedValue = model.wrappedValue }
            .onChange(of: model.wrappedValue) { view.wrappedValue = model.wrappedValue }
            .onChange(of: view.wrappedValue) { model.wrappedValue = view.wrappedValue }
    }
}
