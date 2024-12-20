import Design
import SwiftUI

struct TabGridView: View {
    let model: TabGridModel

    private let columns = [
        GridItem(.adaptive(minimum: TabCellLayout.minSize.width), spacing: 16)
    ]

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(model.tabCells) { tabCell in
                    switch tabCell {
                    case let .tab(tab):
                        TabCellView(tab: tab) {
                            print("TODO: open \(tab.url.absoluteString)")
                        } delete: {
                            model.deleteButtonTapped(tab: tab)
                        }
                    case .new:
                        NewTabCellView {
                            print("TODO: open new tab")
                        }
                    }
                }
            }
            .padding(16)
        }
        .animation(.smooth, value: model.tabCells)
        .background(Color.topaz600)
    }
}

#Preview {
    return TabGridView(model: previewModel())

    @MainActor
    func previewModel() -> TabGridModel {
        let urls: [URL] = [
            "https://sample.com",
            "https://sample.com",
        ].map { URL(string: $0)! }
        return TabGridModel(urls: urls)
    }
}
