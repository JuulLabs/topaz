import Bluetooth
import BluetoothClient

struct NativeScanner: BluetoothScanner {
    private let filter: Filter
    private let coordinator: Coordinator
    private let continuation: AsyncStream<AdvertisementEvent>.Continuation

    let advertisements: AsyncStream<AdvertisementEvent>

    init(filter: Filter, coordinator: Coordinator) {
        self.filter = filter
        self.coordinator = coordinator
        let (stream, continuation) = AsyncStream<AdvertisementEvent>.makeStream()
        self.advertisements = stream
        self.continuation = continuation
        coordinator.startScanning(filter: filter, callback: handleEvent)
    }

    func handleEvent(_ event: AdvertisementEvent) {
        // TODO: apply filter here
        continuation.yield(event)
    }

    func cancel() {
        coordinator.stopScanning()
        continuation.finish()
    }
}
