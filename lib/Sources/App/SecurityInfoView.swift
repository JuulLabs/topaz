import Design
import SwiftUI

struct SecurityInfoView: View {
    @Environment(\.dismiss) private var dismiss
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
            Button {
                dismiss()
            } label: {
                Text("Ok")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
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
