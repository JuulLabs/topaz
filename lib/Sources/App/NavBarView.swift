import Bluetooth
import SwiftUI
import WebView

struct NavBarView: View {
    let model: NavBarModel

    var body: some View {
        VStack(spacing: 0) {
            if model.shouldShowErrorState {
                BluetoothErrorView(state: model.bluetoothSystem.systemState)
            }
            if let progress = model.progress {
                ProgressView(value: progress)
                    .tint(.white)
                    .frame(height: 4)
                    .animation(.spring(), value: progress)
            } else {
                Rectangle()
                    .fill(Color.topaz600)
                    .frame(height: 4)
            }
            VStack(spacing: 12) {
                SearchBarView(model: model.searchBarModel)
                    .padding(.bottom, 12)
                NavIconStrip(model: model)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.topaz600)
    }
}

#Preview {
    NavBarView(
        model: NavBarModel()
    )
}
