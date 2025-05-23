@testable import EventBus
import Foundation
import TestHelpers
import Testing
import XCTest

extension Tag {
    @Tag static var eventBus: Self
}

@Suite(.tags(.eventBus))
struct EventBusAwaiterTests {

    private let sut = EventBus()
    private let systemStateKey = EventRegistrationKey(name: .systemState)

    @Test
    func awaitEvent_withLaunchEffect_executesEffectImmediately() async throws {
        let effectInvokedExpectation = XCTestExpectation(description: "launchEffect invoked")
        let task = Task<TestEventOne, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey) {
                effectInvokedExpectation.fulfill()
            }
        }
        await Task.bigYield()
        task.cancel()
        let outcome = await XCTWaiter().fulfillment(of: [effectInvokedExpectation], timeout: 1.0)
        #expect(outcome == .completed)
    }

    @Test
    func awaitEvent_withoutPredicate_resolvesWhenSameEventTypeWithMatchingKeyArrives() async throws {
        let expectedEvent = TestEventOne(id: "fake", lookup: .exact(key: systemStateKey))
        let task = Task<TestEventOne, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey)
        }
        await Task.bigYield()
        await sut.resolvePendingRequests(for: expectedEvent)
        let value = try await task.value
        #expect(value == expectedEvent)
    }

    @Test
    func awaitEvent_withoutPredicate_throwsWhenDifferentEventTypeWithMatchingKeyArrives() async throws {
        let otherEvent = TestEventOne(id: "fake", lookup: .exact(key: systemStateKey))
        // Note: The expected event type is given by the type signature of the task here:
        let task = Task<TestEventTwo, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey)
        }
        await Task.bigYield()
        await sut.resolvePendingRequests(for: otherEvent)
        await #expect(throws: EventBusError.typeMismatch(.systemState, expectedType: "\(type(of: TestEventTwo.self))")) {
            try await task.value
        }
    }

    @Test
    func awaitEvent_withoutPredicate_throwsWhenErrorEventWithMatchingKeyArrives() async throws {
        let errorEvent = ErrorEvent(error: FakeError(), lookup: .exact(key: systemStateKey))
        let task = Task<TestEventOne, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey)
        }
        await Task.bigYield()
        await sut.resolvePendingRequests(for: errorEvent)
        await #expect(throws: FakeError()) {
            try await task.value
        }
    }

    @Test
    func awaitEvent_withoutPredicate_throwsWhenCancelled() async throws {
        let fakeEvent = TestEventOne(id: "fake", lookup: .exact(key: systemStateKey))
        let task = Task<TestEventOne, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey)
        }
        await Task.bigYield()
        task.cancel()
        await sut.resolvePendingRequests(for: fakeEvent)
        await #expect {
            try await task.value
        } throws: { (error: any Error) in
            error is CancellationError
        }
    }

    @Test
    func awaitEvent_withPredicate_resolvesWhenPredicateIsSatisfied() async throws {
        let task = Task<TestEventOne, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey, where: { event in
                event.id == "3"
            })
        }
        for id in [1, 2, 3, 4, 5] {
            await Task.bigYield()
            let event = TestEventOne(id: "\(id)", lookup: .exact(key: systemStateKey))
            await sut.resolvePendingRequests(for: event)
        }
        let value = try await task.value
        #expect(value.id == "3")
    }

    @Test
    func awaitEvent_withPredicate_throwsWhenCancelled() async throws {
        let task = Task<TestEventOne, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey) { event in
                event.id == "3"
            }
        }
        for id in [1, 2, 3, 4, 5] {
            await Task.bigYield()
            let otherEvent = TestEventOne(id: "\(id)", lookup: .exact(key: systemStateKey))
            await sut.resolvePendingRequests(for: otherEvent)
            if id == 1 {
                task.cancel()
            }
        }
        await #expect {
            try await task.value
        } throws: { (error: any Error) in
            error is CancellationError
        }
    }

    @Test
    func cancelEverything_cancelsAllAwaiters() async throws {
        let task = Task<TestEventOne, any Error> {
            try await sut.awaitEvent(forKey: systemStateKey)
        }
        await Task.bigYield()
        await sut.cancelEverything(with: FakeError())
        await #expect(throws: FakeError()) {
            try await task.value
        }
    }
}
