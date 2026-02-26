//

import SwiftUI
import Navigation

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
//                .containerRelativeFrame(.vertical)
                .font(.dogpatch(.headline))
                .foregroundStyle(Color.textPrimary)
                .focused($focusedField, equals: .searchBar)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    model.didSubmitSearchString()
                }
//                .border(Color.red)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 50)
//                        .inset(by: -0.25)
//                        .stroke(.white, lineWidth: 0.5)
//                )
//                .background(Color.cellFillPrimary)
            Image(systemName: "microphone")
                .foregroundStyle(Color.textPrimary)
                .font(.system(size: 24).weight(.light))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cellFillPrimary) // 2. Add a background color
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white, lineWidth: 0.25) // 3. Add the border as an overlay
        )
//        .border(Color.red)
    }
}

#Preview {
    let navigator = WebNavigator(loadingState: .initializing)
    let model = SearchBarModel(navigator: navigator)
    SearchBarViewV2(model: model)
}
