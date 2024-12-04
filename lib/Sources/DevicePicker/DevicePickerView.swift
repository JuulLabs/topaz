import Bluetooth
import Observation
import SwiftUI
import Design

public struct DevicePickerView: View {

    private let model: DevicePickerModel

    public init(model: DevicePickerModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .center) {
            Text("Select a device")
                .font(.dogpatch(.title2))
                .foregroundStyle(.white)
            List {
                ForEach(model.advertisements) { advertisement in
                    Button {
                        model.advertisementTapped(advertisement)
                    } label: {
                        PickerLineView(model: advertisement)
                    }
                }
                .listRowBackground(Color.topaz800)
                .listRowSeparatorTint(Color.borderActive)
            }
            .scrollContentBackground(.hidden)
            .task {
                model.task()
            }
        }
        .padding(.top, 14)
        .background(Color.topaz700)
    }
}

#Preview {
    let model = DevicePickerModel(
        siteName: "demo.com",
        selector: DeviceSelector(),
        onDismiss: { print("Dismiss requested") }
    )
    NavigationStack {
        DevicePickerView(model: model)
#if targetEnvironment(simulator)
            .forceLoadFontsInPreview()
            .task {
                await model.selector.injectMockAdsAndStart()
            }
#endif
    }
}
