import Design
import DevicePicker
import Observation
import SwiftUI
import UIHelpers
import WebView

struct SearchBarView: View {
    @Bindable var model: SearchBarModel
    @FocusState private var focusedField: SearchBarModel.FocusedField?

    var body: some View {
        HStack(spacing: 8) {
            styledIcon(systemName: "magnifyingglass")
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
            if let stopOrReloadMode = model.stopOrReloadMode {
                switch stopOrReloadMode {
                case .showStopLoading:
                    Button {
                        model.stopButtonTapped()
                    } label: {
                        styledIcon(systemName: "xmark")
                    }
                case .showReload:
                    Button {
                        model.reloadButtonTapped()
                    } label: {
                        styledIcon(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .padding(12)
        .background(.white)
        .cornerRadius(24)
        .frame(maxWidth: .infinity, minHeight: 48)
        .animation(.interactiveSpring, value: model.stopOrReloadMode)
        .synchronize($model.focusedField, $focusedField)
    }

    @ViewBuilder private func styledIcon(
        systemName: String
    ) -> some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.light))
            .foregroundStyle(Color.steel600)
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

#Preview("Initial") {
    let navigator = WebNavigator(loadingState: .initializing)
    let model = SearchBarModel(navigator: navigator)
    SearchBarView(model: model)
        .padding(40)
        .background(Color.topaz600)
}

#Preview("Loading") {
    let navigator = WebNavigator(loadingState: .inProgress(0.5))
    let model = SearchBarModel(navigator: navigator)
    SearchBarView(model: model)
        .padding(40)
        .background(Color.topaz600)
}

#Preview("Complete") {
    let navigator = WebNavigator(loadingState: .complete)
    let model = SearchBarModel(navigator: navigator)
    SearchBarView(model: model)
        .padding(40)
        .background(Color.topaz600)
}
