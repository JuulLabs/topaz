import Bluetooth
import SwiftUI

struct BluetoothErrorView: View {

    let state: SystemState
    let drawShadow: Bool

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.borderActive)
                        .font(.headline)
                    Text(determineErrorText(for: state))
                        .font(.dogpatch(.headline))
                        .foregroundStyle(Color.textPrimary)
                }
                if state == .unauthorized {
                    Button {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Text("Enable")
                            .font(.dogpatch(.body, weight: .bold))
                            .foregroundStyle(Color.topaz800)
                    }
                    .frame(maxWidth: 88, minHeight: 36)
                    .background(.white)
                    .cornerRadius(24)
                }
            }
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 12)
            if drawShadow {
                Rectangle()
                    .frame(maxWidth: .infinity, maxHeight: 0.5)
                    .foregroundStyle(Color.black)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.topaz800)
    }

    private func determineErrorText(for bluetoothStatus: SystemState) -> String {
        switch bluetoothStatus {
        case .unauthorized: "Bluetooth® permissions disabled"
        case .poweredOff: "Bluetooth® is turned off"
        default: ""
        }
    }
}

#Preview {
    BluetoothErrorView(state: .unauthorized, drawShadow: true)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
