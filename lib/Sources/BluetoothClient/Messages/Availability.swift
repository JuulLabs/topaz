import JsMessage

struct GetAvailabilityResponse: JsMessageEncodable {
    let isAvailable: Bool

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body(["isAvailable": isAvailable])
    }
}

struct AvailabilityEvent: JsEventEncodable {
    let isAvailable: Bool

    func toJsEvent() -> JsEvent {
        JsEvent(targetId: "bluetooth", eventName: "availabilitychanged", body: isAvailable)
    }
}
