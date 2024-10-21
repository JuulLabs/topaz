import Foundation

/**
 A wrapper around `AsyncStream` with lazy access to the continuation.
 */
public struct EmissionStream<T: Sendable>: Sendable {
    private var continuation: AsyncStream<T>.Continuation? = nil
    public private(set) var stream: AsyncStream<T> = AsyncStream { _ in }

    public init(_ initialValue: T? = nil) {
        stream = AsyncStream { continuation in
            self.continuation = continuation
        }
        if let initialValue {
            emit(initialValue)
        }
    }

    public func emit(_ item: T) {
        continuation?.yield(item)
    }

    public func finish() {
        continuation?.finish()
    }
}
