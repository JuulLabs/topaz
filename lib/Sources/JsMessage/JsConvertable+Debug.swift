import Foundation
import Helpers

extension JsConvertable {
    public func asDebugString() -> String {
        debugString(from: jsValue)
    }

    private func debugString(from jsValue: Any) -> String {
        switch jsValue {
        case let value as NSNumber:
            value.asDebugString()
        case let value as NSString:
            value as String
        case let value as NSDate:
            DateFormatter.localizedString(from: value as Date, dateStyle: .short, timeStyle: .short)
        case let value as NSArray:
            arrayAsString(value)
        case let value as NSDictionary:
            dictionaryAsString(value)
        case is NSNull:
            "null"
        default:
            "<\(type(of: self.jsValue))>"
        }
    }

    private func dictionaryAsString(_ data: NSDictionary) -> String {
        let strings = data.map { (key, jsValue) in
            "\(key):\(debugString(from: jsValue))"
        }
        return strings.isEmpty ? "" : "{ \(strings.joined(separator: ", ")) }"
    }

    private func arrayAsString(_ items: NSArray) -> String {
        let strings = items.map(debugString)
        return strings.isEmpty ? "" : "[ \(strings.joined(separator: ", ")) ]"
    }
}
