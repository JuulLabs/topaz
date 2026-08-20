import Bluetooth
import Foundation

/// Restricts interactive device selection to the currently displayed tab.
///
/// Web Bluetooth requires a visible document, plus user activation, for
/// `requestDevice()`. A request from a background tab therefore fails fast rather than
/// present UI over an unrelated tab or hang until the tab is next displayed.
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
        // A background tab scans briefly in requestDevice before its awaitSelection is
        // rejected. Those advertisements must never leak into the picker that the
        // active tab presents on the shared underlying selector.
        guard activeTabState.isActive(tab: tab) else { return }
        await wrapped.showAdvertisement(peripheral: peripheral, advertisement: advertisement)
    }

    public func cancel() async {
        await wrapped.cancel()
    }
}
