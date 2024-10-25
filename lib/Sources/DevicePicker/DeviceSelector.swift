import Bluetooth
import Foundation
import Helpers

// TODO: move to own module with BluetoothEngine

@MainActor
@Observable
public class DeviceSelector: InteractiveDeviceSelector {
    private var selectionContinuaton: CheckedContinuation<Result<AnyPeripheral, DeviceSelectionError>, Never>?
    private var advertisingPeripherals: [UUID: (AnyPeripheral, Advertisement)] = [:]
    private let advertisementsStream = EmissionStream<[Advertisement]>()

    public var advertisements: AsyncStream<[Advertisement]> {
        advertisementsStream.stream
    }

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
    }

    public func awaitSelection() async -> Result<Bluetooth.AnyPeripheral, DeviceSelectionError> {
        isSelecting = true
        advertisementsStream.emit([])
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

    public func showAdvertisement(peripheral: Bluetooth.AnyPeripheral, advertisement: Bluetooth.Advertisement) {
        guard isSelecting else { return }
        advertisingPeripherals[peripheral.identifier] = (peripheral, advertisement)
        advertisementsStream.emit(advertisingPeripherals.values.map { $0.1 })
    }

    public func cancel(with error: DeviceSelectionError = .cancelled) {
        fulfill(returning: .failure(error))
    }

    private func fulfill(returning result: Result<Bluetooth.AnyPeripheral, DeviceSelectionError>) {
        guard let continuation = selectionContinuaton else { return }
        selectionContinuaton = nil
        continuation.resume(returning: result)
    }
}
