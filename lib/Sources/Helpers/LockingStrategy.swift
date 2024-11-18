import Dispatch
import Foundation

public protocol LockingStrategy: Sendable {
    func withLock(block: () -> Void)
}

public struct QueueLockingStrategy: LockingStrategy {
    let queue: DispatchQueue

    public init(queue: DispatchQueue) {
        self.queue = queue
    }

    public func withLock(block: () -> Void) {
        queue.sync {
            block()
        }
    }
}

// TODO: move to unit test helpers module
public struct NonLockingStrategy: LockingStrategy {

    public init() {
    }

    public func withLock(block: () -> Void) {
        block()
    }
}
