import Bluetooth
import Foundation

public struct ScanTask: Sendable {
    public let id: String
    public let scan: BluetoothLEScan
    public let task: Task<(), Never>

    public init(
        id: String,
        scan: BluetoothLEScan,
        task: Task<(), Never>
    ) {
        self.id = id
        self.scan = scan
        self.task = task
    }

    public func cancel() {
        task.cancel()
    }
}
