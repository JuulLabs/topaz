import Bluetooth
import Design
import SwiftUI

struct BluetoothErrorView: View {

    let state: SystemState
    let drawShadow: Bool

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.iconDefault)
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
                            .font(.dogpatch(.headline))
                            .foregroundStyle(Color.textPrimaryInverse)
                    }
                    .frame(maxWidth: 88, minHeight: 40)
                    .background(Color.buttonDefault)
                    .cornerRadius(24)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding([.top, .bottom], 16)
        }
        .frame(width: 330)
        .embedInRoundedRectangle(cornerRadius: 48)
        
    }

    private func determineErrorText(for bluetoothStatus: SystemState) -> String {
        switch bluetoothStatus {
        case .unauthorized: "Bluetooth® permissions disabled."
        case .poweredOff: "Bluetooth® is turned off."
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

#Preview {
    BluetoothErrorView(state: .poweredOff, drawShadow: true)
#if targetEnvironment(simulator)
        .forceLoadFontsInPreview()
#endif
}
