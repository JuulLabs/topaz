import Foundation
import JsMessage
import TestHelpers
import Testing
@testable import WebView

@MainActor
private final class DeliverySpy {
    private(set) var delivered: [String] = []
    private(set) var overflowCount = 0
    var gate: CheckedContinuation<Void, Never>?
    var blockDeliveries = false

    func makeQueue(
        capacity: Int = 4,
        deliveryTimeout: Duration = .seconds(30),
        backgroundEpoch: @escaping @MainActor () -> Int = { 0 }
    ) -> JsEventDeliveryQueue {
        JsEventDeliveryQueue(
            capacity: capacity,
            deliveryTimeout: deliveryTimeout,
            backgroundEpoch: backgroundEpoch,
            deliver: { [weak self] event in
                guard let self else { return .success(()) }
                if self.blockDeliveries {
                    await withCheckedContinuation { continuation in
                        self.gate = continuation
                    }
                }
                self.delivered.append(event.eventName)
                return .success(())
            },
            onOverflow: { [weak self] in
                self?.overflowCount += 1
            }
        )
    }

    func openGate() {
        gate?.resume()
        gate = nil
    }
}

private func event(_ name: String) -> JsEvent {
    JsEvent(.bluetooth, targetId: "test", eventName: name)
}

@MainActor
private final class EpochCounter {
    private var value = 0

    func advance() -> Int {
        value += 1
        return value
    }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct JsEventDeliveryQueueTests {

    @Test
    func enqueue_withSeveralEvents_deliversThemInOrder() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        queue.enqueue(event("one"))
        queue.enqueue(event("two"))
        queue.enqueue(event("three"))
        while spy.delivered.count < 3 {
            await Task.yield()
        }
        #expect(spy.delivered == ["one", "two", "three"])
    }

    @Test
    func enqueue_whileADeliveryIsBlocked_returnsPromptly() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        spy.blockDeliveries = true
        let first = queue.enqueue(event("one"))
        let second = queue.enqueue(event("two"))
        guard case .success = first, case .success = second else {
            Issue.record("Expected both enqueues to be accepted")
            return
        }
        #expect(spy.delivered.isEmpty)
        spy.blockDeliveries = false
        spy.openGate()
        while spy.delivered.count < 2 {
            await Task.yield()
        }
        #expect(spy.delivered == ["one", "two"])
    }

    @Test
    func enqueue_whenTheBufferIsFull_reportsOverflowAndCancelsTheQueue() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue(capacity: 2)
        spy.blockDeliveries = true
        // The blocked drain task pulls the first event out of the buffer. The buffer
        // therefore overflows only when two more events wait in it and a fourth arrives.
        queue.enqueue(event("one"))
        while spy.gate == nil {
            await Task.yield()
        }
        queue.enqueue(event("two"))
        queue.enqueue(event("three"))
        let overflowing = queue.enqueue(event("four"))
        guard case let .failure(error) = overflowing else {
            Issue.record("Expected overflow failure")
            return
        }
        #expect(error as? JsEventDeliveryError == .overflow)
        #expect(spy.overflowCount == 1)
        #expect(queue.isCancelled)
        spy.openGate()
    }

    @Test
    func enqueue_afterTheQueueIsCancelled_isRejectedWithoutReportingOverflow() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        queue.cancel()
        let result = queue.enqueue(event("one"))
        guard case let .failure(error) = result else {
            Issue.record("Expected cancelled failure")
            return
        }
        #expect(error as? JsEventDeliveryError == .cancelled)
        #expect(spy.overflowCount == 0)
        #expect(spy.delivered.isEmpty)
    }

    @Test
    func cancel_whileEventsAreBuffered_dropsThem() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        spy.blockDeliveries = true
        queue.enqueue(event("one"))
        await Task.yield()
        queue.enqueue(event("two"))
        queue.cancel()
        spy.blockDeliveries = false
        spy.openGate()
        await Task.yield()
        await Task.yield()
        // The event that was mid-delivery may complete, but buffered ones are dropped
        #expect(!spy.delivered.contains("two"))
    }

    @Test
    func enqueue_whenADeliveryNeverCompletes_timesOutAndAbandonsThePage() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue(deliveryTimeout: .milliseconds(50))
        spy.blockDeliveries = true
        queue.enqueue(event("one"))
        // The WebKit delivery callback is not cancellable. The queue must not park its
        // drain task forever behind it, so the timeout converges like an overflow.
        while spy.overflowCount == 0 {
            await Task.yield()
        }
        #expect(queue.isCancelled)
        #expect(spy.delivered.isEmpty)
        spy.blockDeliveries = false
        spy.openGate()
        await Task.bigYield()
        #expect(spy.overflowCount == 1)
    }

    @Test
    func enqueue_whenDeliveriesCompleteWithinTheTimeout_deliversWithoutAbandoningThePage() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue(deliveryTimeout: .seconds(30))
        queue.enqueue(event("one"))
        queue.enqueue(event("two"))
        while spy.delivered.count < 2 {
            await Task.yield()
        }
        #expect(spy.delivered == ["one", "two"])
        #expect(spy.overflowCount == 0)
        #expect(!queue.isCancelled)
    }

    @Test
    func enqueue_whenTheDeadlineElapsesAcrossABackgroundSuspension_rearmsTheTimeout() async throws {
        let spy = DeliverySpy()
        let epoch = EpochCounter()
        // Every sample reports a further background transition. No deadline ever elapses
        // entirely in the foreground, so the page is never indicted.
        let queue = spy.makeQueue(deliveryTimeout: .milliseconds(10), backgroundEpoch: { epoch.advance() })
        spy.blockDeliveries = true
        queue.enqueue(event("one"))
        try await Task.sleep(for: .milliseconds(200))
        #expect(spy.overflowCount == 0)
        #expect(!queue.isCancelled)
        spy.blockDeliveries = false
        spy.openGate()
    }

    @Test
    func awaitPendingDeliveries_whileEventsArePending_waitsForThemToLand() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        spy.blockDeliveries = true
        queue.enqueue(event("one"))
        while spy.gate == nil {
            await Task.yield()
        }
        queue.enqueue(event("two"))
        let barrier = Task { await queue.awaitPendingDeliveries() }
        await Task.bigYield()
        #expect(spy.delivered.isEmpty)
        spy.blockDeliveries = false
        spy.openGate()
        await barrier.value
        #expect(spy.delivered == ["one", "two"])
    }

    @Test
    func awaitPendingDeliveries_whenNothingIsPending_returnsImmediately() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        queue.enqueue(event("one"))
        while spy.delivered.count < 1 {
            await Task.yield()
        }
        await queue.awaitPendingDeliveries()
        #expect(spy.delivered == ["one"])
    }

    @Test
    func awaitPendingDeliveries_whenTheQueueIsCancelled_isReleased() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        spy.blockDeliveries = true
        queue.enqueue(event("one"))
        queue.enqueue(event("two"))
        let barrier = Task { await queue.awaitPendingDeliveries() }
        await Task.bigYield()
        // Teardown must not strand a request waiting on an event that will never land
        queue.cancel()
        await barrier.value
        spy.blockDeliveries = false
        spy.openGate()
    }

    @Test
    func enqueue_afterAnEarlierDeliveryLands_resumesDrainingTheBacklog() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue(capacity: 2)
        queue.enqueue(event("one"))
        while spy.delivered.count < 1 {
            await Task.yield()
        }
        queue.enqueue(event("two"))
        queue.enqueue(event("three"))
        while spy.delivered.count < 3 {
            await Task.yield()
        }
        #expect(spy.delivered == ["one", "two", "three"])
        #expect(!queue.isCancelled)
    }
}
