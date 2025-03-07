import Bluetooth
import Foundation

public struct ScanTask: Sendable {
    public let id: String
    public let task: Task<(), Never>

    public init(
        id: String,
        task: Task<(), Never>
    ) {
        self.id = id
        self.task = task
    }

    public func cancel() {
        task.cancel()
    }
}
