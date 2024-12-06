import Bluetooth
import Foundation

struct PickerLineModel {

    static let defaultName = "unnamed"

    let ad: Advertisement
    var name: String {
        // TODO: derive visual string from the identifier when unnamed
        ad.peripheralName ?? ad.localName ?? PickerLineModel.defaultName
    }
}

extension PickerLineModel: Identifiable {
    var id: UUID { ad.peripheralId }
}
