import Foundation

public struct JsEvent: Sendable {
    public let targetId: String
    public let eventName: String
    public let body: (Sendable & Encodable)?

    public init(targetId: String, eventName: String, body: (Sendable & Encodable)?) {
        self.targetId = targetId
        self.eventName = eventName
        self.body = body
    }
}
