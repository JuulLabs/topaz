import Design
import SwiftUI

public struct TabGridView: View {
    let model: TabGridModel

    private let columns = [
        GridItem(.adaptive(minimum: TabCellLayout.minSize.width), spacing: 16)
    ]

    public init(model: TabGridModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(model.tabCells) { tabCell in
                        TabCellView(tab: tabCell) {
                            model.tabButtonTapped(tab: tabCell)
                        } delete: {
                            model.deleteButtonTapped(tab: tabCell)
                        }
                    }
                }
                .padding(16)
            }
            .animation(.smooth, value: model.tabCells)
            .background(Color.topaz800)
            TabManagementToolbarView(model: model)
        }
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
