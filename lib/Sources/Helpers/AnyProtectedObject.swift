
/// A type-erased `ProtectedObject`
public struct AnyProtectedObject: Sendable {
    public let wrapped: ProtectedObject<AnyObject>

    public init<T: AnyObject>(wrapping wrapped: T, in locker: any LockingStrategy) {
        self.wrapped = ProtectedObject(object: wrapped, locker: locker)
    }

    public func withLock<T: AnyObject>(block: (T) -> Void) {
        wrapped.withLock { erased in
            guard let unerased = erased as? T else { return }
            block(unerased)
        }
    }
}

extension AnyProtectedObject: Equatable {
    public static func == (lhs: AnyProtectedObject, rhs: AnyProtectedObject) -> Bool {
        lhs.wrapped == rhs.wrapped
    }
}
