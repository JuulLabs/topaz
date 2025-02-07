import Bluetooth
import BluetoothClient

struct NativeScanner: BluetoothScanner {
    private let options: Options?
    private let coordinator: Coordinator
    private let continuation: AsyncStream<AdvertisementEvent>.Continuation

    let advertisements: AsyncStream<AdvertisementEvent>

    init(options: Options?, coordinator: Coordinator) {
        self.options = options
        self.coordinator = coordinator
        let (stream, continuation) = AsyncStream<AdvertisementEvent>.makeStream()
        self.advertisements = stream
        self.continuation = continuation
        let services = options?.filters?.compactMap { $0.services?.compactMap { $0 } }.flatMap { $0 } ?? []
        coordinator.startScanning(serviceUuids: services, callback: handleEvent)
    }

    func handleEvent(_ event: AdvertisementEvent) {
        // If no options are provided, yield all
        guard let options = options else {
            continuation.yield(event)
            return
        }

        // If options are provided, only yield events that pass the filters
        if options.includeAdvertisementEventInDeviceList(event) {
            continuation.yield(event)
        }
    }

    func cancel() {
        coordinator.stopScanning()
        continuation.finish()
    }
}
