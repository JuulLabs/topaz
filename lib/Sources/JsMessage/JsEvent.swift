import Foundation

public struct JsEvent: Sendable, JsConvertable {
    public let targetId: String
    public let eventName: String
    public let body: (Sendable & JsConvertable)?

    public init(targetId: String, eventName: String, body: (Sendable & JsConvertable)? = nil) {
        self.targetId = targetId
        self.eventName = eventName
        self.body = body
    }

    // Aligns with the TargetedEvent type defined in Javascript
    private func asDictionary() -> [String: JsConvertable] {
        [
            "id": targetId,
            "name": eventName,
            "data": body,
        ]
    }

    public var jsValue: Any {
        asDictionary().jsValue
    }
}
