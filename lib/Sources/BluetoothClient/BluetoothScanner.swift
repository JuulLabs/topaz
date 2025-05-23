import Bluetooth
import EventBus

public protocol BluetoothScanner: Sendable {
    var advertisements: AsyncStream<AdvertisementEvent> { get }
    func cancel()
}
