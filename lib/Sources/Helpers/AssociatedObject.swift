import Foundation

/**
 Swift wrapper for leveraging objc_get/setAssociatedObject to add properties in extensions.

 Example use:
 ```
 extension SomeObject {
    final class ExtraStorage: AssociatedObject {
        var someValue: Int = 0
    }

    var someValue: Int {
        get { get(ExtraStorage.self).someValue }
        set { get(ExtraStorage.self).someValue = newValue }
    }
 }
 ```
 */
public protocol AssociatedObject: AnyObject {
    static var key: UnsafeRawPointer { get }
    init()
}

public extension AssociatedObject {
    static var key: UnsafeRawPointer { UnsafeRawPointer(bitPattern: UInt(bitPattern: ObjectIdentifier(Self.self)))! }
}

public extension NSObject {
    func get<Object: AssociatedObject>(_ objectClass: Object.Type ) -> Object {
        var object = objc_getAssociatedObject(self, Object.key) as? Object
        if object == nil {
            object = objectClass.init()
            objc_setAssociatedObject(self, Object.key, object, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return object!
    }
}
