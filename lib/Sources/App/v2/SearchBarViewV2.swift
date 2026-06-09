import SwiftUI
import Navigation
import UIHelpers

struct SearchBarViewV2: View {

    @Bindable var model: SearchBarModel
    @FocusState private var focusedField: SearchBarModel.FocusedField?

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textPrimary)
                .font(.system(size: 24).weight(.light))
            TextField(
                "Search",
                text: $model.searchString,
                prompt: Text("Search")
                    .foregroundStyle(Color.textPrimary)
                    .font(.dogpatch(.headline))
            )
                .frame(maxHeight: .infinity)
                .font(.dogpatch(.headline))
                .foregroundStyle(Color.textPrimary)
                .focused($focusedField, equals: .searchBar)
                .keyboardType(.webSearch)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    model.didSubmitSearchString()
                }
            if let clearOrReloadMode = model.clearOrReloadMode {
                switch clearOrReloadMode {
                case .showClear:
                    Button {
                        model.clearSearchFieldTapped()
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(Color.textPrimary)
                            .font(.system(size: 20).weight(.light))
                    }
                case .showReload:
                    Button {
                        model.reloadButtonTapped()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.textPrimary)
                            .font(.system(size: 20).weight(.light))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: 48)
        .background(Color.clear)
        .synchronize($model.focusedField, $focusedField)
    }
}

#Preview {
    let navigator = WebNavigator(loadingState: .initializing)
    let model = SearchBarModel(navigator: navigator)
    SearchBarViewV2(model: model)
}
