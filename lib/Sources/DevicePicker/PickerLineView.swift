import SwiftUI

struct PickerLineView: View {
    let model: PickerLineModel

    var body: some View {
        HStack {
            Text(model.name)
                .fontWeight(.bold)
            Text("Power: \(model.ad.rssi)")
                .font(.footnote)
        }
    }
}
