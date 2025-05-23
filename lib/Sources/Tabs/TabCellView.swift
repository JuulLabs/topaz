import Design
import SwiftUI

struct TabCellView: View {
    let tab: TabModel
    let action: () -> Void
    let delete: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            URLPreviewImage(url: tab.url)
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
