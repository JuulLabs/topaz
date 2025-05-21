import SwiftUI

struct TabManagementToolbarView: View {

    let model: TabGridModel

    var body: some View {
        Button {
            model.openNewTabButtonTapped()
        } label: {
            Image(systemName: "plus.square.fill")
                .foregroundStyle(Color.borderActive)
                .imageScale(.large)
                .font(.title)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.topaz600)
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
