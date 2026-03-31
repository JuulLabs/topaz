import SwiftUI
import UIHelpers

struct TabManagementToolbarView: View {

    let model: TabGridModel

    var body: some View {
        Button {
            model.openNewTabButtonTapped()
        } label: {
            Image(systemName: "plus.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.iconDefault, Color.cellFillPrimary)
                .imageScale(.large)
                .font(.largeTitle.weight(.light))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .embedInNavigationBackground(keyboardPresent: false)
    }
}

#Preview {
    return TabManagementToolbarView(model: previewModel())
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif

    @MainActor
    func previewModel() -> TabGridModel {
        let urls: [URL] = [
            "https://sample.com",
            "https://sample.com",
        ].map { URL(string: $0)! }
        return TabGridModel(urls: urls)
    }
}
