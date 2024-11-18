import Bluetooth
import Foundation

public struct TestDeviceSelector: InteractiveDeviceSelector {

    public init() {}

    public func awaitSelection() async -> Result<Bluetooth.Peripheral, DeviceSelectionError> {
        fatalError("Not implemented")
    }

    public func makeSelection(_ identifier: UUID) async {
        fatalError("Not implemented")
    }

    public func showAdvertisement(peripheral: Bluetooth.Peripheral, advertisement: Bluetooth.Advertisement) async {
        fatalError("Not implemented")
    }

    public func cancel(with error: DeviceSelectionError) async {
        fatalError("Not implemented")
    }
}
