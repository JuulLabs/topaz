import Foundation

extension NSNumber {
    public func asDebugString() -> String {
        isBoolean ? "\(boolValue)" : stringValue
    }

    public var isBoolean: Bool {
        CFGetTypeID(self) == CFBooleanGetTypeID()
    }

    public func asHexString() -> String {
        String(format: "0x%02llx", uint64Value)
    }
}
