import Foundation

/// Structured data representing a DOMException
public struct DomError: Sendable, Encodable, Error {
    public let name: DomErrorName
    public let msg: String?

    public init(name: DomErrorName, message: String? = nil) {
        self.name = name
        self.msg = message
    }

    enum DomErrorEncodingError: Error {
        case jsonStringEncode
    }
}

extension DomError: JsErrorStringRepresentable {
    /// Js side of the pipe will decode this JSON and convert to a DOMException
    public var jsRepresentation: String {
        do {
            let json = try JSONEncoder().encode(self)
            guard let jsonString = String(data: json, encoding: .utf8) else {
                throw DomErrorEncodingError.jsonStringEncode
            }
            return jsonString
        } catch {
            // We got an error on our error! Presumably the error text contained something crazy
            // Return a hand-rolled JSON struct and deliberately exclude the offending non-codeable text
            // TODO: log this somewhere
            // TODO: It may be useful to display an alert on the web page for this case as well
            return """
                {
                    "name": "\(DomErrorName.encoding.rawValue)",
                    "msg": "\(Self.self) caused by \(name)"
                }
            """
        }
    }
}

public protocol DomErrorConvertable {
    var domErrorName: DomErrorName { get }
}

extension Error {
    public func toDomError() -> DomError {
        guard let name = (self as? DomErrorConvertable)?.domErrorName else {
            // TODO: log this case where we probably forgot to add conformance to one of the error types
            return DomError(name: .unknown, message: "\(Self.self): \(self.localizedDescription)")
        }
        return DomError(name: name, message: self.localizedDescription)
    }
}
