import Foundation
import Semaphore

/**
 Holds a value that may arrive in the future.
 */
public actor StateValue<Value: Sendable>: Sendable {
    private var value: Value
    private let semaphore = AsyncSemaphore(value: 0)

    public init(initialValue: Value) {
        self.value = initialValue
    }

    /**
     Setting the value will resume any tasks that are awaiting a value.
     */
    public func setValue(_ newValue: Value) {
        value = newValue
        while semaphore.signal() {
        }
    }

    /**
     Awaits until a value is set and then returns it.
     May return nil if cancelled before a value arrives.
     */
    public func getValue() async -> Value? {
        try? await semaphore.waitUnlessCancelled()
        return value
    }
}
