import JsMessage
import Testing

extension JsMessageResponse {
    func extractBody<T>(as: T.Type) -> T? {
        switch self {
        case let .body(body):
            return body.jsValue as? T
        case let .error(error):
            Issue.record("Unexpected error response: \(error)")
            return .none
        }
    }
}
