@testable import BluetoothClient
import JsMessage
import Testing

extension JsMessageEncodable {
    func encodeForTesting<T>() -> T? {
        let encoded = toJsMessage()
        guard case let .body(body) = encoded else {
            Issue.record("Unexpected response: \(encoded)")
            return nil
        }
        return body.jsValue as? T
    }
}
