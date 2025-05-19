@testable import EventBus
import Foundation
import JsMessage
import TestHelpers
import Testing
import XCTest

@Suite(.tags(.eventBus))
struct EventBusJsTests {

    private let fakeContextId = JsContextIdentifier(tab: 0, url: URL.init(filePath: .init()))
    private let sut = EventBus()

    @Test
    func sendJsEvent_withoutContext_returnsFailure() async throws {
        let event = JsEvent(targetId: "test-id", eventName: "test-event")
        let result = await sut.sendJsEvent(event)
        switch result {
        case .success:
            Issue.record("Unexpected result: \(result)")
        case let .failure(anyError):
            let error = try #require(anyError as? EventBusError)
            #expect(error == EventBusError.jsContextUnavailable)
        }
    }

    @Test
    func sendJsEvent_withContextThatFails_returnsFailure() async throws {
        let context = JsContext(id: fakeContextId) { _ in
                .failure(FakeError())
        }
        await sut.setJsContext(context)
        let event = JsEvent(targetId: "test-id", eventName: "test-event")
        let result = await sut.sendJsEvent(event)
        switch result {
        case .success:
            Issue.record("Unexpected result: \(result)")
        case let .failure(anyError):
            let error = try #require(anyError as? FakeError)
            #expect(error == FakeError())
        }
    }

    @Test
    func sendJsEvent_withContextThatSucceeds_emitsEvent() async {
        let expectedEvent = JsEvent(targetId: "test-id", eventName: "test-event")
        let eventSentExpectation = XCTestExpectation(description: "listenerCallback invoked")
        let context = JsContext(id: fakeContextId) { event in
            #expect(event.eventName == expectedEvent.eventName)
            eventSentExpectation.fulfill()
            return .success(())
        }
        await sut.setJsContext(context)
        let result = await sut.sendJsEvent(expectedEvent)
        switch result {
        case .success:
            break
        case let .failure(error):
            Issue.record("Unexpected result: \(error)")
        }
        let outcome = await XCTWaiter().fulfillment(of: [eventSentExpectation], timeout: 0.1)
        #expect(outcome == .completed)
    }
}
