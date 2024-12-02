import SwiftUI
import Design

struct PickerLineView: View {
    let model: PickerLineModel

    var body: some View {
        HStack {
            Text(model.name)
                .font(.dogpatch(.headline))
                .foregroundStyle(Color.interactiveTextPrimary)
//            Text("Power: \(model.ad.rssi)")
//                .font(.footnote)
            Spacer()
            Image(media: .signalThree)
        }
//        .listRowSeparatorTint(.white)
        .alignmentGuide(.listRowSeparatorLeading) { _ in

            // 2
            return -20 //Fills the width of the list
//            return -viewDimensions.width
//            return viewDimensions[.leading]
        }
//        .listRowBackground(Color.topaz800)
    }
}
