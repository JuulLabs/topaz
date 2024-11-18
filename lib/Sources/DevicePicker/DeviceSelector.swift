import Bluetooth
import Foundation

// TODO: move to own module with BluetoothEngine

@MainActor
@Observable
public class DeviceSelector: InteractiveDeviceSelector {
    private var selectionContinuaton: CheckedContinuation<Result<Peripheral, DeviceSelectionError>, Never>?
    private var advertisingPeripherals: [UUID: (Peripheral, Advertisement)] = [:]
    private let advertisementsContinuation: AsyncStream<[Advertisement]>.Continuation

    public var advertisements: AsyncStream<[Advertisement]>

    // Exposed as a Binding for driving UI presentation state
    // SwiftUI will write false to this when the user swipes away the modal
    public var isSelecting: Bool = false {
        didSet {
            if isSelecting == false && selectionContinuaton != nil {
                // Modal was dismissed via gesture
                // TODO: unit test that continuation is not leaked or double-resumed
                fulfill(returning: .failure(.cancelled))
            }
        }
    }

    public init() {
        let (stream, continuation) = AsyncStream<[Advertisement]>.makeStream()
        self.advertisements = stream
        self.advertisementsContinuation = continuation
    }

    public func awaitSelection() async -> Result<Bluetooth.Peripheral, DeviceSelectionError> {
        isSelecting = true
        advertisementsContinuation.yield([])
        defer {
            advertisingPeripherals = [:]
            isSelecting = false
        }
        return await withCheckedContinuation { continuation in
            selectionContinuaton = continuation
        }
    }

    public func makeSelection(_ identifier: UUID) {
        if let (peripheral, _) = advertisingPeripherals[identifier] {
            fulfill(returning: .success(peripheral))
        } else {
            fulfill(returning: .failure(.invalidSelection))
        }
    }

    public func showAdvertisement(peripheral: Bluetooth.Peripheral, advertisement: Bluetooth.Advertisement) {
        guard isSelecting else { return }
        advertisingPeripherals[peripheral.id] = (peripheral, advertisement)
        advertisementsContinuation.yield(advertisingPeripherals.values.map { $0.1 })
    }

    public func cancel(with error: DeviceSelectionError = .cancelled) {
        fulfill(returning: .failure(error))
    }

    private func fulfill(returning result: Result<Bluetooth.Peripheral, DeviceSelectionError>) {
        guard let continuation = selectionContinuaton else { return }
        selectionContinuaton = nil
        continuation.resume(returning: result)
    }
}
