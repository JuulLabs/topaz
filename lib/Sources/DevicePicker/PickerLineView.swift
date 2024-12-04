import SwiftUI
import Design

struct PickerLineView: View {
    let model: PickerLineModel

    var body: some View {
        HStack {
            Text(model.name)
                .font(.dogpatch(.headline))
                .foregroundStyle(Color.textPrimary)
//            Text("Power: \(model.ad.rssi)")
//                .font(.footnote)
            Spacer()
            Image(media: determineSignalImage(basedOn: model.ad.rssi))
        }
//        .listRowSeparatorTint(.white)
        .alignmentGuide(.listRowSeparatorLeading) { _ in

            // 2
            return -16 //Fills the width of the list
//            return -viewDimensions.width
//            return viewDimensions[.leading]
        }
//        .listRowBackground(Color.topaz800)
    }

    private func determineSignalImage(basedOn rssi: Int) -> MediaImage {
        print(rssi)
//        return .signalThree
//        switch rssi {
//        case _ where rssi >= -60:
//            MediaImage.signalThree
//        case -60 ... -70:
//            MediaImage.signalTwo
//        case -70 ... -85:
//            MediaImage.signalThree
//        default:
//            MediaImage.signalNone
//        }
        return switch rssi {
        case -60...Int.max:
                .signalThree
        case -70 ... -60:
                .signalTwo
        case -85 ... -70:
                .signalOne
        default:
                .signalNone
        }
    }
}
