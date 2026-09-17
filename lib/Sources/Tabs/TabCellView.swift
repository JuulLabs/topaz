import Design
import SwiftUI

struct TabCellView: View {
    let tab: TabModel
    let loadPreview: (UUID) async -> Data?
    let action: () -> Void
    let delete: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            URLPreviewImage(tab: tab, loadPreview: loadPreview)
                .tabCellLayout()
                .overlay(alignment: .topTrailing) {
                    Button {
                        delete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.textSecondary)
                            .padding(12)
                    }
                }
        }
    }
}
