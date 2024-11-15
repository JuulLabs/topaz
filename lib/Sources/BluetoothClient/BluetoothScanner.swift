import Bluetooth

public protocol BluetoothScanner: Sendable {
    var advertisements: AsyncStream<AdvertisementEvent> { get }
    func cancel()
}
