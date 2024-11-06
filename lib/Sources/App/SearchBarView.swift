import Design
import DevicePicker
import Observation
import SwiftUI
import UIHelpers
import WebView

struct SearchBarView: View {
    @Bindable var model: SearchBarModel
    @FocusState private var focusedField: FocusedField?

    enum FocusedField {
        case searchBar
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .fontWeight(.ultraLight)
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
        .onAppear {
            focusedField = .searchBar
        }
    }
}
