import Bluetooth
import EventBus

public struct MockScanner: BluetoothScanner {
    public let continuation: AsyncStream<AdvertisementEvent>.Continuation
    public let advertisements: AsyncStream<AdvertisementEvent>

    public init() {
        let (stream, continuation) = AsyncStream<AdvertisementEvent>.makeStream()
        self.advertisements = stream
        self.continuation = continuation
    }

    public func cancel() {
        continuation.finish()
    }
}
