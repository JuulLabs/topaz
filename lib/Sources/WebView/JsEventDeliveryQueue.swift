import Foundation
import JsMessage
import OSLog
import UIKit

private let log = Logger(subsystem: "Topaz", category: "JsEventDeliveryQueue")

/// Counts transitions to the background. The app declares no background modes, so it is
/// suspended while backgrounded: timers do not run, but their deadlines keep expiring
/// against the continuous clock and land in a batch on resume. A deadline that spans a
/// suspension therefore says nothing about whether the page is still responsive.
@MainActor
final class AppBackgroundEpoch {
    static let shared = AppBackgroundEpoch()

    private(set) var value = 0

    private init() {
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                self?.value += 1
            }
        }
    }
}

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
/// preserving order; `awaitPendingDeliveries()` exposes that order to a reply that must
/// not overtake its own event. Individual delivery failures are logged and skipped (matching the
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
    private let backgroundEpoch: @MainActor () -> Int
    private var buffer: [JsEvent] = []
    private var drainTask: Task<Void, Never>?
    private(set) var isCancelled = false

    /// Counts events accepted and events whose delivery has finished (successfully or
    /// not), so a barrier can name a point in the stream and wait for it to pass.
    private var enqueuedCount = 0
    private var deliveredCount = 0
    private var barriers: [(threshold: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(
        capacity: Int = JsEventDeliveryQueue.defaultCapacity,
        deliveryTimeout: Duration = JsEventDeliveryQueue.defaultDeliveryTimeout,
        backgroundEpoch: @escaping @MainActor () -> Int = { AppBackgroundEpoch.shared.value },
        deliver: @escaping @MainActor (JsEvent) async -> Result<Void, any Error>,
        onOverflow: @escaping @MainActor () -> Void
    ) {
        self.capacity = capacity
        self.deliveryTimeout = deliveryTimeout
        self.backgroundEpoch = backgroundEpoch
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
        enqueuedCount += 1
        drainIfNeeded()
        return .success(())
    }

    /// Waits until every event accepted before this call has reached the page. Callers
    /// that must not let a reply overtake its own event - a characteristic read, whose
    /// value the page reads from the event - await this before replying. The wait is
    /// borne by the requesting page, never by the producer feeding the queue.
    func awaitPendingDeliveries() async {
        guard !isCancelled, deliveredCount < enqueuedCount else { return }
        let threshold = enqueuedCount
        await withCheckedContinuation { continuation in
            barriers.append((threshold: threshold, continuation: continuation))
        }
    }

    /// Stops delivery and drops any buffered events. Idempotent.
    func cancel() {
        isCancelled = true
        buffer.removeAll()
        drainTask?.cancel()
        drainTask = nil
        // Nothing more will ever be delivered, so waiters must not be stranded
        releaseBarriers(upTo: enqueuedCount)
    }

    private func releaseBarriers(upTo delivered: Int) {
        let reached = barriers.filter { $0.threshold <= delivered }
        barriers.removeAll { $0.threshold <= delivered }
        reached.forEach { $0.continuation.resume() }
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
                self.deliveredCount += 1
                self.releaseBarriers(upTo: self.deliveredCount)
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
    ///
    /// The timeout only indicts the page for time the app actually spent running: a
    /// deadline that elapsed across a background suspension is re-armed instead, so
    /// switching away from a healthy tab mid-delivery cannot cost it its session.
    private func deliverRacingTimeout(_ event: JsEvent) async -> Result<Void, any Error> {
        let deliver = self.deliver
        let timeout = self.deliveryTimeout
        let backgroundEpoch = self.backgroundEpoch
        return await withCheckedContinuation { continuation in
            let oneShot = OneShotResume(continuation)
            let timerTask = Task { @MainActor in
                do {
                    var epoch = backgroundEpoch()
                    while true {
                        try await Task.sleep(for: timeout)
                        let currentEpoch = backgroundEpoch()
                        guard currentEpoch == epoch else {
                            epoch = currentEpoch
                            continue
                        }
                        oneShot.resume(.failure(JsEventDeliveryError.timedOut))
                        return
                    }
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
