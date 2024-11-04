import Semaphore

final class PendingAction<T: Sendable> {
    private var continuation: CheckedContinuation<T, any Error>?

    func awaitResolved(isolation: isolated (any Actor)? = #isolation) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resolve(with value: T) {
        continuation?.resume(returning: value)
    }

    func reject(with error: any Error) {
        continuation?.resume(throwing: error)
    }

    func resolve(with value: T, orRejectIf error: (any Error)? = nil) {
        switch error {
        case .none: resolve(with: value)
        case let .some(error): reject(with: error)
        }
    }
}
