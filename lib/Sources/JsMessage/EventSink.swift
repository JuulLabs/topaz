import Foundation
import Semaphore

public actor EventSink: JsMessageProcessor {
    private var unsentEvents: [JsEvent] = []
    private let semaphore = AsyncSemaphore(value: 0)

    public init() {
    }

    public func send(_ event: JsEvent) {
        unsentEvents.append(event)
        semaphore.signal()
    }

    // MARK: - JsMessageProcessor
    public let handlerName: String = "eventsink"

    public func didAttach(to context: JsContext) async {
        // No-op
    }

    // We ignore the request - it is empty anyway. Just send back all queued events.
    // Note we are using a non-binary semaphore asymmetrically so ignore if the queue is empty
    public func process(request: JsMessageRequest) async -> JsMessageResponse {
        repeat {
            try? await semaphore.waitUnlessCancelled()
        } while unsentEvents.isEmpty && !Task.isCancelled
        let eventsToSend: [JsConvertable] = unsentEvents
        unsentEvents = []
        return .body(eventsToSend)
    }
}
