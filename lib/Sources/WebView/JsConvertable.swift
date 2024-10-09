import Foundation

/**
 A native value expressed as a Javascript compatible type erased to Any.
 Allowed types are NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull.
 */
protocol JsConvertable: Sendable {
    var jsValue: Any { get }
}

extension Bool: JsConvertable {
    var jsValue: Any {
        NSNumber(value: self)
    }
}

extension Int: JsConvertable {
    var jsValue: Any {
        NSNumber(value: self)
    }
}

extension Double: JsConvertable {
    var jsValue: Any {
        NSNumber(value: self)
    }
}

extension String: JsConvertable {
    var jsValue: Any {
        self as NSString
    }
}

extension Date: JsConvertable {
    var jsValue: Any {
        self as NSDate
    }
}

extension Optional: JsConvertable where Wrapped == JsConvertable {
    var jsValue: Any {
        switch self {
        case .none:
            NSNull()
        case let .some(wrapped):
            wrapped.jsValue
        }
    }
}

extension Array: JsConvertable where Element == JsConvertable {
    var jsValue: Any {
        map { $0.jsValue } as NSArray
    }
}

extension Dictionary: JsConvertable where Key == String, Value == JsConvertable {
    var jsValue: Any {
        compactMapValues { $0.jsValue } as NSDictionary
    }
}
