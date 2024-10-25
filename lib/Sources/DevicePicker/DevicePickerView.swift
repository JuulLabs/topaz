import Bluetooth
import Observation
import SwiftUI

public struct DevicePickerView: View {

    private let model: DevicePickerModel

    public init(model: DevicePickerModel) {
        self.model = model
    }

    public var body: some View {
        List {
            ForEach(model.advertisements) { advertisement in
                Button {
                    model.advertisementTapped(advertisement)
                } label: {
                    PickerLineView(model: advertisement)
                }
            }
        }
        .task {
            model.task()
        }
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
            .navigationTitle("Select Device")
#if targetEnvironment(simulator)
            .task {
                await model.selector.injectMockAdsAndStart()
            }
#endif
    }
}
