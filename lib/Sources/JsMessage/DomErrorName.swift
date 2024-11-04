
/// https://webidl.spec.whatwg.org/#idl-DOMException-error-names
public enum DomErrorName: String, Sendable, Encodable {
    case abort = "AbortError"
    case encoding = "EncodingError"
    case notFound = "NotFoundError"
    case operataion = "OperationError"
    case unknown = "UnknownError"
}
