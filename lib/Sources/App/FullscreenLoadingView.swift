import SwiftUI

struct FullscreenLoadingView: View {
    var body: some View {
        ZStack {
            Color.topaz600
            ProgressView()
                .controlSize(.extraLarge)
                .tint(.white)
        }
        .ignoresSafeArea(.all)
    }
}
