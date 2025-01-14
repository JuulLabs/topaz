
/// https://webidl.spec.whatwg.org/#idl-DOMException-error-names
public enum DomErrorName: String, Sendable, Encodable {
    case abort = "AbortError"
    case encoding = "EncodingError"
    case network = "NetworkError"
    case notFound = "NotFoundError"
    case notSupported = "NotSupportedError"
    case operataion = "OperationError"
    case unknown = "UnknownError"
}
