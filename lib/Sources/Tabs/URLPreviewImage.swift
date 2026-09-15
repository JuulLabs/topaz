import Design
import SwiftUI

/// The tab's last captured thumbnail, falling back to its hostname while no thumbnail
/// exists. Loaded lazily per cell: the system caches the decoded bitmap, and a purged
/// or never-captured thumbnail simply shows the fallback.
struct URLPreviewImage: View {
    let tab: TabModel
    let loadPreview: (UUID) async -> Data?

    @State private var preview: UIImage?

    private var hostname: String {
        tab.url.host(percentEncoded: false) ?? tab.url.absoluteString
    }

    var body: some View {
        ZStack {
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(hostname)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding()
                    .foregroundStyle(Color.white)
            }
        }
        .task(id: PreviewKey(tab: tab)) {
            preview = await loadPreview(tab.tabID).flatMap(UIImage.init(data:))
        }
    }

    private struct PreviewKey: Equatable {
        let tabID: UUID
        let generation: Int

        init(tab: TabModel) {
            self.tabID = tab.tabID
            self.generation = tab.previewGeneration
        }
    }
}
