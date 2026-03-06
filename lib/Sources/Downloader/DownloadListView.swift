import Design
import SwiftUI

public struct DownloadListView: View {
    private let model: Downloads

    public init(model: Downloads) {
        self.model = model
    }

    public var body: some View {
        if model.downloads.isEmpty {
            ContentUnavailableView(
                "No downloads",
                systemImage: "arrow.down.circle",
                description: Text("Downloads you start will appear here.")
            )
            .background(Color.backgroundPrimary)
        } else {
            List {
                ForEach(model.downloads) { downloadModel in
                    DownloadRowView(model: downloadModel)
                }
                .onDelete { indexSet in
                    model.delete(indexSet: indexSet)
                }
                .listRowBackground(Color.backgroundPrimary)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.topaz700)
        }
    }
}
