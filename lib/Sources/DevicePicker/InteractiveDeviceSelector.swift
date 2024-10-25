import Bluetooth
import Foundation

@MainActor
public protocol InteractiveDeviceSelector: Sendable {
    /// Blocks until `makeSelection` is invoked and returns the selected device
    func awaitSelection() async -> Result<AnyPeripheral, DeviceSelectionError>
    /// Selects the specified device
    func makeSelection(_ identifier: UUID) async
    /// Injects advertisements to be shown to the user from which they may make a selection
    func showAdvertisement(peripheral: AnyPeripheral, advertisement: Advertisement) async
    /// Cancels the selection process
    func cancel(with error: DeviceSelectionError) async
}
