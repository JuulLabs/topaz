import Bluetooth
import Foundation

struct PickerLineModel {
    let ad: Advertisement
    var name: String {
        // TODO: derive visual string from the identifier when unnamed
        ad.peripheralName ?? ad.localName ?? "unnamed"
    }
}

extension PickerLineModel: Identifiable {
    var id: UUID { ad.peripheralId }
}
