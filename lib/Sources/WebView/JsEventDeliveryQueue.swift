import Foundation
import JsMessage
import OSLog

private let log = Logger(subsystem: "Topaz", category: "JsEventDeliveryQueue")

enum JsEventDeliveryError: Error, LocalizedError, Equatable {
    case overflow
    case cancelled
    case timedOut

    var errorDescription: String? {
        switch self {
        case .overflow:
            return "Event delivery buffer overflowed"
        case .cancelled:
            return "Event delivery queue is cancelled"
        case .timedOut:
            return "Event delivery timed out"
        }
    }
}

/// Decouples Js event delivery from the producer so a slow or suspended web page can
/// never stall the tab's Bluetooth engine event loop.
///
/// Events are accepted immediately into a bounded FIFO buffer and delivered serially,
/// preserving order. Individual delivery failures are logged and skipped (matching the
/// previous log-and-continue semantics). If the buffer overflows - the page has been
/// unresponsive under sustained event traffic for a long time - the queue cancels
/// itself and reports it via `onOverflow`, whose owner is expected to tear down the
/// session (converge-to-empty) rather than lose data silently. A single delivery that
/// never completes (WebKit's callback is not cancellable) is bounded by
/// `deliveryTimeout` and converges the same way.
@MainActor
final class JsEventDeliveryQueue {
    static let defaultCapacity = 256
    static let defaultDeliveryTimeout: Duration = .seconds(30)

    private let capacity: Int
    private let deliveryTimeout: Duration
    private let deliver: @MainActor (JsEvent) async -> Result<Void, any Error>
    private let onOverflow: @MainActor () -> Void
    private var buffer: [JsEvent] = []
    private var drainTask: Task<Void, Never>?
    private(set) var isCancelled = false

    init(
        capacity: Int = JsEventDeliveryQueue.defaultCapacity,
        deliveryTimeout: Duration = JsEventDeliveryQueue.defaultDeliveryTimeout,
        deliver: @escaping @MainActor (JsEvent) async -> Result<Void, any Error>,
        onOverflow: @escaping @MainActor () -> Void
    ) {
        self.capacity = capacity
        self.deliveryTimeout = deliveryTimeout
        self.deliver = deliver
        self.onOverflow = onOverflow
    }

    /// Accepts an event for ordered delivery, returning promptly even when the page is
    /// not currently consuming deliveries.
    @discardableResult
    func enqueue(_ event: JsEvent) -> Result<Void, any Error> {
        guard !isCancelled else {
            return .failure(JsEventDeliveryError.cancelled)
        }
        guard buffer.count < capacity else {
            log.error("Delivery buffer overflow at \(self.capacity) events; abandoning the page")
            cancel()
            onOverflow()
            return .failure(JsEventDeliveryError.overflow)
        }
        buffer.append(event)
        drainIfNeeded()
        return .success(())
    }

    /// Stops delivery and drops any buffered events. Idempotent.
    func cancel() {
        isCancelled = true
        buffer.removeAll()
        drainTask?.cancel()
        drainTask = nil
    }

    private func drainIfNeeded() {
        guard drainTask == nil else { return }
        drainTask = Task { @MainActor [weak self] in
            while true {
                guard let self, !self.isCancelled, !Task.isCancelled else { return }
                guard !self.buffer.isEmpty else {
                    self.drainTask = nil
                    return
                }
                let event = self.buffer.removeFirst()
                let result = await self.deliverRacingTimeout(event)
                if case let .failure(error) = result {
                    if (error as? JsEventDeliveryError) == .timedOut {
                        // WebKit never resumed the delivery callback: the page is
                        // wedged (or its continuation lost). Converge like overflow -
                        // abandon the page - instead of parking this task forever.
                        guard !self.isCancelled else { return }
                        log.error("Event delivery timed out for \(event.eventName, privacy: .public); abandoning the page")
                        self.cancel()
                        self.onOverflow()
                        return
                    }
                    log.error("Event delivery failed \(event.eventName, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    /// Runs a delivery racing a timeout. The underlying `callAsyncJavaScript`
    /// continuation is not cancellable, so a wedged page would otherwise strand the
    /// drain task (and everything it keeps alive) forever; the loser of the race is
    /// left to resolve - or leak inside WebKit - on its own.
    private func deliverRacingTimeout(_ event: JsEvent) async -> Result<Void, any Error> {
        let deliver = self.deliver
        let timeout = self.deliveryTimeout
        return await withCheckedContinuation { continuation in
            let oneShot = OneShotResume(continuation)
            let timerTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: timeout)
                    oneShot.resume(.failure(JsEventDeliveryError.timedOut))
                } catch {
                    // Cancelled: the delivery finished first
                }
            }
            Task { @MainActor in
                let result = await deliver(event)
                timerTask.cancel()
                oneShot.resume(result)
            }
        }
    }
}

/// Resolves a continuation at most once when racing multiple completion paths.
@MainActor
private final class OneShotResume {
    private var continuation: CheckedContinuation<Result<Void, any Error>, Never>?

    init(_ continuation: CheckedContinuation<Result<Void, any Error>, Never>) {
        self.continuation = continuation
    }

    func resume(_ result: Result<Void, any Error>) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}
