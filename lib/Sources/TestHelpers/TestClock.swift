import Synchronization

/// A clock whose time only moves when a test calls `advance(by:)`, so timer-driven code
/// runs deterministically regardless of how loaded the machine is.
public final class TestClock: Clock, Sendable {
    public struct Instant: InstantProtocol {
        fileprivate let offset: Duration

        public func advanced(by duration: Duration) -> Self {
            Instant(offset: offset + duration)
        }

        public func duration(to other: Self) -> Duration {
            other.offset - offset
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    private struct Sleeper {
        let id: UInt64
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct SleeperWaiter {
        let count: Int
        let continuation: CheckedContinuation<Void, Never>
    }

    private struct State {
        var now = Instant(offset: .zero)
        var nextID: UInt64 = 0
        var sleepers: [Sleeper] = []
        var waiters: [SleeperWaiter] = []

        mutating func takeSatisfiedWaiters() -> [CheckedContinuation<Void, Never>] {
            let satisfied = waiters.filter { sleepers.count >= $0.count }
            waiters.removeAll { sleepers.count >= $0.count }
            return satisfied.map(\.continuation)
        }
    }

    private let state = Mutex(State())

    public init() {}

    public var now: Instant {
        state.withLock { $0.now }
    }

    public var minimumResolution: Duration {
        .zero
    }

    public func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        let id = state.withLock { state in
            defer { state.nextID += 1 }
            return state.nextID
        }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let (immediate, waiters) = state.withLock { state -> (Result<Void, any Error>?, [CheckedContinuation<Void, Never>]) in
                    // Checked under the lock so a cancellation racing this registration is never missed
                    if Task.isCancelled {
                        return (.failure(CancellationError()), [])
                    }
                    if deadline <= state.now {
                        return (.success(()), [])
                    }
                    state.sleepers.append(Sleeper(id: id, deadline: deadline, continuation: continuation))
                    return (nil, state.takeSatisfiedWaiters())
                }
                if let immediate {
                    continuation.resume(with: immediate)
                }
                waiters.forEach { $0.resume() }
            }
        } onCancel: {
            let sleeper = state.withLock { state -> Sleeper? in
                guard let index = state.sleepers.firstIndex(where: { $0.id == id }) else { return nil }
                return state.sleepers.remove(at: index)
            }
            sleeper?.continuation.resume(throwing: CancellationError())
        }
    }

    /// Moves time forward, waking every sleeper whose deadline has been reached.
    public func advance(by duration: Duration) {
        let due = state.withLock { state in
            state.now = state.now.advanced(by: duration)
            let now = state.now
            let due = state.sleepers.filter { $0.deadline <= now }
            state.sleepers.removeAll { $0.deadline <= now }
            return due
        }
        due.forEach { $0.continuation.resume() }
    }

    /// Suspends until at least `count` tasks are sleeping on this clock, so a test can
    /// advance time knowing the timers it targets have been scheduled.
    public func waitForSleepers(count: Int = 1) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let ready = state.withLock { state in
                if state.sleepers.count >= count {
                    return true
                }
                state.waiters.append(SleeperWaiter(count: count, continuation: continuation))
                return false
            }
            if ready {
                continuation.resume()
            }
        }
    }
}
