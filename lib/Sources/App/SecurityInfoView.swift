import Design
import SwiftUI

struct SecurityInfoView: View {
    let mode: SearchBarModel.InfoIconMode

    private var hostString: String {
        mode.url.host().map { "the website \($0)" } ?? "this website"
    }

    var body: some View {
        VStack(spacing: 32) {
            switch mode {
            case .showInsecure:
                Image(systemName: "exclamationmark.triangle")
                    .imageScale(.large)
                    .font(.largeTitle)
                    .foregroundStyle(Color.redNotification)
                Text("Warning: Unsafe Connection")
                    .font(.title)
                Text("Information is not encrypted when communicating with \(hostString).")
                    .font(.body)
            case .showSecure:
                Image(systemName: "lock")
                    .imageScale(.large)
                    .font(.largeTitle)
                    .tint(.primary)
                Text("Encrypted Connection")
                    .font(.title)
                Text("Encryption keeps information private when communicating with \(hostString).")
                    .font(.body)
            }
        }
        .padding()
    }
}

#Preview("Secure") {
    let url = URL(string: "https://alwaysssl.com/")!
    SecurityInfoView(mode: .showSecure(url))
}

#Preview("Insecure") {
    let url = URL(string: "http://neverssl.com/")!
    SecurityInfoView(mode: .showInsecure(url))
}
