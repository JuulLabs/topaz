import Foundation

/*
 Interprets an erased Any originating from Javascript back into a native swift type.
 */
public enum JsType: Sendable {
    case number(NSNumber)
    case string(String)
    case date(Date)
    case array(Array<JsType>)
    case dictionary(Dictionary<String, JsType>)
    case null
}

extension JsType {
    // TODO: can we support undefined aka Never?
    public static func canBridge(_ jsValue: Any) -> Bool {
        switch jsValue {
        case is NSNumber:
            true
        case is NSString:
            true
        case is NSDate:
            true
        case let array as NSArray:
            array.allSatisfy(canBridge)
        case let dictionary as NSDictionary:
            dictionary.allKeys.allSatisfy { $0 is NSString } && dictionary.allValues.allSatisfy(canBridge)
        case is NSNull:
            true
        default:
            false
        }
    }

    public static func bridge(_ jsValue: Any) -> JsType {
        switch jsValue {
        case let number as NSNumber:
            .number(number)
        case let string as NSString:
            .string(string as String)
        case let date as NSDate:
            .date(date as Date)
        case let array as NSArray:
            .array(array.map { JsType.bridge($0) })
        case let dictionary as NSDictionary:
            .dictionary(
                dictionary.reduce(into: [String: JsType]()) { result, pair in
                    guard let key = pair.key as? String else {
                        fatalError("Invalid key expected string but got \(type(of: pair.key))")
                    }
                    result[key] = JsType.bridge(pair.value)
                }
            )
        case is NSNull:
            .null
        default:
            fatalError("Unsupported type \(type(of: jsValue))")
        }
    }

    public static func bridgeOrNull(_ jsValue: Any) -> JsType? {
        canBridge(jsValue) ? bridge(jsValue) : .none
    }
}

extension JsType {
    public var number: NSNumber? {
        guard case let .number(value) = self else { return .none }
        return value
    }

    public var string: String? {
        guard case let .string(value) = self else { return .none }
        return value
    }

    public var date: Date? {
        guard case let .date(value) = self else { return .none }
        return value
    }

    public var array: [JsType]? {
        guard case let .array(value) = self else { return .none }
        return value
    }

    public var dictionary: [String: JsType]? {
        guard case let .dictionary(value) = self else { return .none }
        return value
    }

    public var data: Data? {
        string.flatMap { Data(base64Encoded: $0) }
    }
}
