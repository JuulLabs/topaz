import Bluetooth
import BluetoothClient
import Foundation

public actor Scanner {
    private var scanningTask: Task<(), Never>?

    private let client: RequestClient
    private let effector: Effector

    init(
        client: RequestClient,
        effector: Effector
    ) {
        self.client = client
        self.effector = effector
    }

    func scan(filter: Filter) -> AsyncThrowingStream<AdvertisementEffect, any Error> {
        let (stream, continuation) = AsyncThrowingStream<AdvertisementEffect, any Error>.makeStream()
        guard scanningTask == nil else {
            continuation.finish()
            return stream
        }
        let task = Task {
            client.startScanning(filter)
            var failure: Error?
            while failure == nil && !Task.isCancelled {
                do {
                    let result = try await effector.getAdvertisement()
                    continuation.yield(result)
                } catch {
                    failure = error
                }
            }
            continuation.finish(throwing: failure)
        }
        continuation.onTermination = { termination in
            task.cancel()
        }
        scanningTask = task
        return stream
    }

    func stopScanning() {
        client.stopScanning()
        scanningTask?.cancel()
        scanningTask = nil
    }
}
