import Foundation
import Semaphore

/**
 Holds a value that can change over time, and provides a mechanism for consumers to await those changes.
 */
public actor StateValue<Value: Sendable>: Sendable {
    private var value: Value
    private let semaphore: AsyncSemaphore

    public init(initialValue: Value, emitOnStart: Bool = false) {
        self.value = initialValue
        self.semaphore = AsyncSemaphore(value: emitOnStart ? 1 : 0)
    }

    /**
     Setting the value will resume any tasks that are awaiting a new value.
     */
    public func setValue(_ newValue: Value) {
        value = newValue
        // TODO: this is racey we actually need a `semaphore.signalAll()` operation instead
        while semaphore.signal() {
        }
    }

    /**
     Awaits until the value changes and then returns it.
     If cancelled while waiting, the existing value will be returned.
     */
    public func getValue() async -> Value {
        try? await semaphore.waitUnlessCancelled()
        return value
    }
}
