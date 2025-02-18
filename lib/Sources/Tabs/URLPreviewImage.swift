import SwiftUI

struct URLPreviewImage: View {
    let url: URL?

    var body: some View {
        // TODO: load image from storage
        Text("\(url?.absoluteString ?? "New Page")")
            .padding()
            .foregroundStyle(Color.white)
    }
}
