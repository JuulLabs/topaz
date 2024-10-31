import Design
import SwiftUI
import UIHelpers

struct FreshPageView: View {
    let searchBarModel: SearchBarModel

    var body: some View {
        ZStack {
            Color.topaz600
            SearchBarView(model: searchBarModel)
                .padding(.horizontal, 24)
        }
        .onTapGesture {
            // Tap outside to dismiss the keyboard
            resignFirstResponder()
        }
    }
}

#Preview {
    let model = SearchBarModel()
    FreshPageView(searchBarModel: model)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
