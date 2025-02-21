import SwiftUI

struct TabManagementToolbarView: View {

    let model: TabGridModel

    var body: some View {
        HStack {
            Button {
                model.openNewTabButtonTapped()
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.borderActive)
                    .imageScale(.large)
                    .font(.title2)
            }
            Spacer()
            Button {
                model.doneButtonTapped()
            } label: {
                Text("Done")
                    .foregroundStyle(Color.textPrimary)
                    .font(.dogpatch(.headline))
                    .bold()
            }
        }
        .padding([.leading, .trailing], 24)
        .padding([.top, .bottom], 16)
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
