import Bluetooth
import SwiftUI
import WebView

struct NavBarView: View {
    let loadingState: WebPageLoadingState
    let searchBarModel: SearchBarModel
    let model: NavBarModel

    @State var bluetoothState: SystemState = .unknown

    var body: some View {
        VStack(spacing: 0) {
            if bluetoothState != .unknown && bluetoothState != .poweredOn {
                BluetoothErrorView(state: bluetoothState)
            }
            if let progress = model.deriveProgress(loadingState: loadingState) {
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
                SearchBarView(model: searchBarModel)
                    .padding(.bottom, 12)
                NavIconStrip(model: model)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.topaz600)
        .task {
            await listenToBluetoothState()
        }
    }

    func listenToBluetoothState() async {
        for await state in model.bluetoothStateStream {
            bluetoothState = state
        }
    }
}

#Preview {
    NavBarView(
        loadingState: .initializing,
        searchBarModel: SearchBarModel(),
        model: NavBarModel()
    )
}
