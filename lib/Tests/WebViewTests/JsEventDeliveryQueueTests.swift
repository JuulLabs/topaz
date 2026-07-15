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

    func makeQueue(capacity: Int = 4, deliveryTimeout: Duration = .seconds(30)) -> JsEventDeliveryQueue {
        JsEventDeliveryQueue(
            capacity: capacity,
            deliveryTimeout: deliveryTimeout,
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
@Suite(.timeLimit(.minutes(1)))
struct JsEventDeliveryQueueTests {

    @Test func enqueue_deliversEventsInOrder() async throws {
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

    @Test func enqueue_returnsPromptlyWhileDeliveryIsBlocked() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue()
        spy.blockDeliveries = true
        // Both enqueues return synchronously even though no delivery can complete
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

    @Test func enqueue_beyondCapacityTriggersOverflowAndCancels() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue(capacity: 2)
        spy.blockDeliveries = true
        // First event is pulled out of the buffer by the (blocked) drain task, so the
        // buffer overflows once two more are pending and a fourth arrives
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

    @Test func enqueue_afterCancelIsRejectedWithoutOverflow() async throws {
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

    @Test func cancel_dropsBufferedEvents() async throws {
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

    @Test func delivery_thatNeverCompletesTimesOutAndAbandonsThePage() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue(deliveryTimeout: .milliseconds(50))
        spy.blockDeliveries = true
        queue.enqueue(event("one"))
        // WebKit's delivery callback is not cancellable; the queue must not park its
        // drain task forever behind it - the timeout converges like an overflow
        while spy.overflowCount == 0 {
            await Task.yield()
        }
        #expect(queue.isCancelled)
        #expect(spy.delivered.isEmpty)
        // Releasing the parked delivery afterwards is harmless
        spy.blockDeliveries = false
        spy.openGate()
        await Task.bigYield()
        #expect(spy.overflowCount == 1)
    }

    @Test func delivery_thatCompletesInTimeDoesNotTrip() async throws {
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

    @Test func drainResumesAfterBacklogClears() async throws {
        let spy = DeliverySpy()
        let queue = spy.makeQueue(capacity: 2)
        queue.enqueue(event("one"))
        while spy.delivered.count < 1 {
            await Task.yield()
        }
        // Queue is idle again: a later burst is delivered in order
        queue.enqueue(event("two"))
        queue.enqueue(event("three"))
        while spy.delivered.count < 3 {
            await Task.yield()
        }
        #expect(spy.delivered == ["one", "two", "three"])
        #expect(!queue.isCancelled)
    }
}
