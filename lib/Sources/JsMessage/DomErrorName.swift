
/// https://webidl.spec.whatwg.org/#idl-DOMException-error-names
public enum DomErrorName: String, Sendable, Encodable {
    case abort = "AbortError"
    case encoding = "EncodingError"
    case network = "NetworkError"
    case notFound = "NotFoundError"
    case notSupported = "NotSupportedError"
    case operation = "OperationError"
    case type = "TypeError"
    case unknown = "UnknownError"
}
