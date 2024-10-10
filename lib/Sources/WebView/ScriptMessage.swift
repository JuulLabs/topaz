import Foundation

struct ScriptMessageRequest: Sendable {
    let name: String
    let body: Dictionary<String, JsType>
}

enum ScriptMessageResponse: Sendable {
    case body(JsConvertable)
    case error(String)
}
