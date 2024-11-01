
/// https://webidl.spec.whatwg.org/#idl-DOMException-error-names
public enum DomErrorName: String, Sendable, Encodable {
    case unknown = "UnknownError"
    case notFound = "NotFoundError"
    case encoding = "EncodingError"
}
