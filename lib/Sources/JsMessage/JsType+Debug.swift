import Foundation
import Helpers

extension JsType {
    public func asDebugString() -> String {
        switch self {
        case let .number(number): number.asDebugString()
        case let .string(string): string
        case let .date(date): DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
        case let .array(items): arrayAsString(items)
        case let .dictionary(data): Self.dictionaryAsString(data)
        case .null: "null"
        }
    }

    public static func dictionaryAsString(_ data: [String: JsType]?) -> String {
        guard let data else { return "" }
        let strings = data.map { (key, value) in
            "\(key):\(value.asDebugString())"
        }
        return strings.isEmpty ? "" : "{ \(strings.joined(separator: ", ")) }"
    }

    private func arrayAsString(_ items: [JsType]) -> String {
        let strings = items.map { $0.asDebugString() }
        return strings.isEmpty ? "" : "[ \(strings.joined(separator: ", ")) ]"
    }
}
