//
import Bluetooth
import SwiftUI

struct BLEErrorView: View {

//    let model: BLEStatusModelable
    let state: SystemState

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.borderActive)
                    .frame(width: 24, height: 24)
                //                .font(.system(size: 24))
                Text(determineErrorText(for: state))
                    .font(.dogpatch(.headline))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize()
                    .lineLimit(1)
            }
            if state == .unauthorized {
                Button {

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
        .frame(maxWidth: .infinity)
        .padding([.leading, .trailing], 16)
        .padding([.top, .bottom], 12)
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

enum BLEStatus {
    case ready
    case off
    case denied
}

protocol BLEStatusModelable {
    var bleStatus: BLEStatus { get }
}

struct MockBLEStatusModel: BLEStatusModelable {
    var bleStatus: BLEStatus = .off
}
