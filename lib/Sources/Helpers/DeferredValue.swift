import Foundation
import Semaphore

/**
 Holds a value that may arrive in the future.
 */
public actor DeferredValue<Value: Sendable>: Sendable {
    private var value: Value?
    private let semaphore = AsyncSemaphore(value: 0)

    public init(initialValue: Value? = nil) {
        if let initialValue {
            self.value = initialValue
        }
    }

    /**
     Setting the value will resume any tasks that are awaiting a value.
     */
    public func setValue(_ newValue: Value) {
        let shouldSignal = value == nil
        value = newValue
        if shouldSignal {
            while semaphore.signal() {
            }
        }
    }

    /**
     Awaits until there is a value and then returns it.
     May return nil if cancelled before a value arrives.
     */
    public func getValue() async -> Value? {
        if let value { return value }
        try? await semaphore.waitUnlessCancelled()
        return value
    }
}
