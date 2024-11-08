import Foundation

/**
 A native value expressed as a Javascript compatible type erased to Any.
 Allowed types are NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull.
 */
public protocol JsConvertable: Sendable {
    var jsValue: Any { get }
}

extension Bool: JsConvertable {
    public var jsValue: Any {
        NSNumber(value: self)
    }
}

extension Int: JsConvertable {
    public var jsValue: Any {
        NSNumber(value: self)
    }
}

extension UInt32: JsConvertable {
    public var jsValue: Any {
        NSNumber(value: self)
    }
}

extension Double: JsConvertable {
    public var jsValue: Any {
        NSNumber(value: self)
    }
}

extension String: JsConvertable {
    public var jsValue: Any {
        self as NSString
    }
}

extension Date: JsConvertable {
    public var jsValue: Any {
        self as NSDate
    }
}

extension Optional: JsConvertable where Wrapped == JsConvertable {
    public var jsValue: Any {
        switch self {
        case .none:
            NSNull()
        case let .some(wrapped):
            wrapped.jsValue
        }
    }
}

extension Array: JsConvertable where Element == JsConvertable {
    public var jsValue: Any {
        map { $0.jsValue } as NSArray
    }
}

extension Dictionary: JsConvertable where Key == String, Value == JsConvertable {
    public var jsValue: Any {
        compactMapValues { $0.jsValue } as NSDictionary
    }
}

extension Data: JsConvertable {
    public var jsValue: Any {
        base64EncodedString() as NSString
    }
}

private struct JsNull: JsConvertable {
    var jsValue: Any { NSNull() }
}

public let jsNull: JsConvertable = JsNull()
