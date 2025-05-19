
/// https://webidl.spec.whatwg.org/#idl-DOMException-error-names
public enum DomErrorName: String, Sendable, Equatable, Encodable {
    case abort = "AbortError"
    case encoding = "EncodingError"
    case invalidState = "InvalidStateError"
    case network = "NetworkError"
    case notAllowed = "NotAllowedError"
    case notFound = "NotFoundError"
    case notSupported = "NotSupportedError"
    case operation = "OperationError"
    case security = "SecurityError"
    case type = "TypeError"
    case unknown = "UnknownError"
}
