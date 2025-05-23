@testable import EventBus
import Foundation
import TestHelpers
import Testing
import XCTest

@Suite(.tags(.eventBus))
struct EventBusListenerTests {

    private let sut = EventBus()
    private let systemStateKey = EventRegistrationKey(name: .systemState)

    @Test
    func emitEvent_withKeyedListener_emitsMatchingEventsOnly() async {
        let eventReceivedExpectation = XCTestExpectation(description: "eventReceived invoked")
        eventReceivedExpectation.expectedFulfillmentCount = 5
        eventReceivedExpectation.assertForOverFulfill = true
        await sut.attachEventListener(forKey: systemStateKey) { (result: Result<TestEventOne, any Error>) in
            if case .success = result {
                eventReceivedExpectation.fulfill()
            }
        }
        for id in [1, 2, 3, 4, 5] {
            let matchingEvent = TestEventOne(id: "\(id)", lookup: .exact(key: systemStateKey))
            await sut.emitEvent(matchingEvent)
            let otherEvent = TestEventTwo(id: "\(id)", lookup: .exact(key: systemStateKey))
            await sut.emitEvent(otherEvent)
        }
        let outcome = await XCTWaiter().fulfillment(of: [eventReceivedExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }

    @Test
    func emitEvent_withKeyedListener_detachesListenerOnErrorEvent() async {
        let successExpectation = XCTestExpectation(description: "success event")
        successExpectation.expectedFulfillmentCount = 1
        successExpectation.assertForOverFulfill = true
        let errorExpectation = XCTestExpectation(description: "error event")
        errorExpectation.expectedFulfillmentCount = 1
        errorExpectation.assertForOverFulfill = true
        await sut.attachEventListener(forKey: systemStateKey) { (result: Result<TestEventOne, any Error>) in
            switch result {
            case .success:
                successExpectation.fulfill()
            case .failure:
                errorExpectation.fulfill()
            }
        }

        // Send success
        let matchingEvent = TestEventOne(id: "test-event", lookup: .exact(key: systemStateKey))
        await sut.emitEvent(matchingEvent)
        // Send failure - causes listener to detach
        let errorEvent = ErrorEvent(error: FakeError(), lookup: .exact(key: systemStateKey))
        await sut.emitEvent(errorEvent)
        // Expect these additional events to be ignored
        await sut.emitEvent(matchingEvent)
        await sut.emitEvent(errorEvent)

        let outcome = await XCTWaiter().fulfillment(of: [successExpectation, errorExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }

    @Test
    func emitEvent_withGenericListener_emitsAllEvents() async {
        let eventReceivedExpectation = XCTestExpectation(description: "eventReceived invoked")
        eventReceivedExpectation.expectedFulfillmentCount = 10
        eventReceivedExpectation.assertForOverFulfill = true
        let listenerKey = EventBusListenerKey(listenerId: "test-listener", filter: .unfiltered)
        await sut.attachGenericListener(listenerKey: listenerKey) { _ in
            eventReceivedExpectation.fulfill()
        }
        for id in [1, 2, 3, 4, 5] {
            let matchingEvent = TestEventOne(id: "\(id)", lookup: .exact(key: systemStateKey))
            await sut.emitEvent(matchingEvent)
            let otherEvent = TestEventTwo(id: "\(id)", lookup: .exact(key: systemStateKey))
            await sut.emitEvent(otherEvent)
        }
        let outcome = await XCTWaiter().fulfillment(of: [eventReceivedExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }

    @Test
    func enqueueEvent_singleEvent_emitsOnce() async {
        let eventReceivedExpectation = XCTestExpectation(description: "eventReceived invoked")
        eventReceivedExpectation.expectedFulfillmentCount = 1
        eventReceivedExpectation.assertForOverFulfill = true
        let listenerKey = EventBusListenerKey(listenerId: "test-listener", filter: .unfiltered)
        await sut.attachGenericListener(listenerKey: listenerKey) { _ in
            eventReceivedExpectation.fulfill()
        }
        let event = TestEventOne(id: "test-event", lookup: .exact(key: systemStateKey))
        sut.enqueueEvent(event)
        let outcome = await XCTWaiter().fulfillment(of: [eventReceivedExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }

    @Test
    func enqueueEvent_manyEvents_emitInOrder() async {
        let (resultStream, resultQueue) = AsyncStream<Int>.makeStream()
        let eventReceivedExpectation = XCTestExpectation(description: "eventReceived invoked")
        eventReceivedExpectation.expectedFulfillmentCount = 10_000
        eventReceivedExpectation.assertForOverFulfill = true
        let listenerKey = EventBusListenerKey(listenerId: "test-listener", filter: .unfiltered)
        await sut.attachGenericListener(listenerKey: listenerKey) { event in
            eventReceivedExpectation.fulfill()
            if let event = event as? TestEventOne, let eventId = Int(event.id) {
                // To capture all results we cannot do mutation in an escaping closure, but we can enqueue to a stream:
                resultQueue.yield(eventId)
            }
        }
        for i in 1...10_000 {
            let event = TestEventOne(id: "\(i)", lookup: .exact(key: systemStateKey))
            sut.enqueueEvent(event)
        }
        let outcome = await XCTWaiter().fulfillment(of: [eventReceivedExpectation], timeout: 0.1)
        #expect(outcome == .completed)
        resultQueue.finish()
        // Check that the order is as expected:
        var counter = 0
        for await eventId in resultStream {
            counter += 1
            #expect(counter == eventId)
        }
        #expect(counter == 10_000)
    }

    @Test
    func detachListener_withKeyedListener_detachesMatchingListener() async {
        let listenerCallbackExpectation = XCTestExpectation(description: "listenerCallback invoked")
        listenerCallbackExpectation.isInverted = true
        await sut.attachEventListener(forKey: systemStateKey) { (_: Result<TestEventOne, any Error>) in
            listenerCallbackExpectation.fulfill()
        }
        await sut.detachListener(forKey: systemStateKey)
        let fakeEvent = TestEventOne(id: "fake", lookup: .exact(key: systemStateKey))
        await sut.emitEvent(fakeEvent)
        let outcome = await XCTWaiter().fulfillment(of: [listenerCallbackExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }

    @Test
    func detachListener_withGenericListener_detachesMatchingListener() async {
        let listenerCallbackExpectation = XCTestExpectation(description: "listenerCallback invoked")
        listenerCallbackExpectation.isInverted = true
        let listenerKey = EventBusListenerKey(listenerId: "test-listener", filter: .unfiltered)
        await sut.attachGenericListener(listenerKey: listenerKey) { _ in
            listenerCallbackExpectation.fulfill()
        }
        await sut.detachListener(forKey: listenerKey)
        let fakeEvent = TestEventOne(id: "fake", lookup: .exact(key: systemStateKey))
        await sut.emitEvent(fakeEvent)
        let outcome = await XCTWaiter().fulfillment(of: [listenerCallbackExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }

    @Test
    func cancelEverything_detachesAllListeners() async {
        let listenerCallbackExpectation = XCTestExpectation(description: "listenerCallback invoked")
        listenerCallbackExpectation.isInverted = true
        await sut.attachEventListener(forKey: systemStateKey) { (_: Result<TestEventOne, any Error>) in
            listenerCallbackExpectation.fulfill()
        }
        let listenerKey = EventBusListenerKey(listenerId: "test-listener", filter: .unfiltered)
        await sut.attachGenericListener(listenerKey: listenerKey) { _ in
            listenerCallbackExpectation.fulfill()
        }
        await sut.cancelEverything(with: FakeError())
        let fakeEvent = TestEventOne(id: "fake", lookup: .exact(key: systemStateKey))
        await sut.emitEvent(fakeEvent)
        let outcome = await XCTWaiter().fulfillment(of: [listenerCallbackExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }
}
