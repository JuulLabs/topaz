//
import Bluetooth
import SwiftUI

struct BLEErrorView: View {

    let state: SystemState

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.borderActive)
                        .frame(width: 24, height: 24)
                    Text(determineErrorText(for: state))
                        .font(.dogpatch(.headline))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize()
                        .lineLimit(1)
                }
                if state == .unauthorized {
                    Button {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Text("Enable")
                            .font(.dogpatch(.body, weight: .bold))
                            .foregroundStyle(Color.topaz800)
                    }
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(.white)
                    .cornerRadius(24)
                }
            }
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 12)
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 0.5, alignment: .bottom)
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity)
        .background(Color.topaz800)
    }

    private func determineErrorText(for bleStatus: SystemState) -> String {
        switch bleStatus {
        case .unauthorized: "Bluetooth® permissions disabled"
        case .poweredOff: "Bluetooth® is turned off"
        default: ""
        }
    }
}

#Preview {
    BLEErrorView(state: .poweredOff)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
