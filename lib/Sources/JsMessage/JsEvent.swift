import Foundation

public struct JsEvent: Sendable, JsConvertable {

    public enum Domain: String, Sendable {
        case bluetooth
        case keyboard
    }

    public let domain: Domain
    public let targetId: String
    public let eventName: String
    public let body: (Sendable & JsConvertable)?

    public init(_ domain: Domain, targetId: String, eventName: String, body: (Sendable & JsConvertable)? = nil) {
        self.domain = domain
        self.targetId = targetId
        self.eventName = eventName
        self.body = body
    }

    // Aligns with the TargetedEvent type defined in Javascript
    private func asDictionary() -> [String: JsConvertable] {
        [
            "domain": domain.rawValue,
            "id": targetId,
            "name": eventName,
            "data": body,
        ]
    }

    public var jsValue: Any {
        asDictionary().jsValue
    }
}
