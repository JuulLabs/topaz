import Foundation
import JsMessage
import OSLog

private let log = Logger(subsystem: "Topaz", category: "JsEventDeliveryQueue")

enum JsEventDeliveryError: Error, LocalizedError {
    case overflow
    case cancelled

    var errorDescription: String? {
        switch self {
        case .overflow:
            return "Event delivery buffer overflowed"
        case .cancelled:
            return "Event delivery queue is cancelled"
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
/// session (converge-to-empty) rather than lose data silently.
@MainActor
final class JsEventDeliveryQueue {
    static let defaultCapacity = 256

    private let capacity: Int
    private let deliver: @MainActor (JsEvent) async -> Result<Void, any Error>
    private let onOverflow: @MainActor () -> Void
    private var buffer: [JsEvent] = []
    private var drainTask: Task<Void, Never>?
    private(set) var isCancelled = false

    init(
        capacity: Int = JsEventDeliveryQueue.defaultCapacity,
        deliver: @escaping @MainActor (JsEvent) async -> Result<Void, any Error>,
        onOverflow: @escaping @MainActor () -> Void
    ) {
        self.capacity = capacity
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
                let deliver = self.deliver
                let result = await deliver(event)
                if case let .failure(error) = result {
                    log.error("Event delivery failed \(event.eventName, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
}
