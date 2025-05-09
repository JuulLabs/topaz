import Bluetooth
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class DevicePickerModel: Identifiable {
    let siteName: String
    let selector: DeviceSelector
    let onDismiss: () -> Void

    private(set) var advertisements: [PickerLineModel] = []

    public init(
        siteName: String,
        selector: DeviceSelector,
        onDismiss: @escaping () -> Void
    ) {
        self.siteName = siteName
        self.selector = selector
        self.onDismiss = onDismiss
    }

    func task() {
        Task { [weak self, selector] in
            for await advertisements in selector.advertisements {
                withAnimation {
                    self?.advertisements = advertisements
                        .map(PickerLineModel.init)
                        .sorted { lhs, rhs in
                            // Pushes unnamed devices to the bottom of the list
                            if lhs.name == PickerLineModel.defaultName {
                                return false
                            } else {
                                return lhs.name.lowercased() < rhs.name.lowercased()
                            }
                        }
                }
            }
        }
    }

    func advertisementTapped(_ adModel: PickerLineModel) {
        selector.makeSelection(adModel.ad.peripheralId)
        withAnimation {
            onDismiss()
        }
    }
}
