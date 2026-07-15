import Bluetooth
import Foundation

/// Restricts interactive device selection to the currently displayed tab.
///
/// The device picker UI is only mounted for the active tab, and Web Bluetooth requires
/// a visible document (plus user activation) for `requestDevice()`. A background tab's
/// request therefore fails fast with a page-visibility error instead of presenting UI
/// over an unrelated tab or hanging until the tab is next displayed.
@MainActor
public final class TabGatedDeviceSelector: InteractiveDeviceSelector {
    private let tab: Int
    private let activeTabState: ActiveTabState
    private let wrapped: InteractiveDeviceSelector

    public init(tab: Int, activeTabState: ActiveTabState, wrapping wrapped: InteractiveDeviceSelector) {
        self.tab = tab
        self.activeTabState = activeTabState
        self.wrapped = wrapped
    }

    public func awaitSelection() async -> Result<Peripheral, DeviceSelectionError> {
        guard activeTabState.isActive(tab: tab) else {
            return .failure(.pageNotVisible)
        }
        return await wrapped.awaitSelection()
    }

    public func makeSelection(_ identifier: UUID) async {
        await wrapped.makeSelection(identifier)
    }

    public func showAdvertisement(peripheral: Peripheral, advertisement: Advertisement) async {
        // A background tab's requestDevice briefly scans before its awaitSelection is
        // rejected; never let those advertisements leak into the picker that the
        // active tab may be presenting on the shared underlying selector
        guard activeTabState.isActive(tab: tab) else { return }
        await wrapped.showAdvertisement(peripheral: peripheral, advertisement: advertisement)
    }

    public func cancel() async {
        await wrapped.cancel()
    }
}
