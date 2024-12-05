import SwiftUI
import Design

struct PickerLineView: View {
    let model: PickerLineModel

    var body: some View {
        HStack {
            Text(model.name)
                .font(.dogpatch(.headline))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Image(media: determineSignalImage(basedOn: model.ad.rssi))
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            return -16 // Fills the width of the list
        }
    }

    private func determineSignalImage(basedOn rssi: Int) -> MediaImage {
        switch rssi {
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
