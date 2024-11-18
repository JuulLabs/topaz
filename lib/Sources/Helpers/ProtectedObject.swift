
/// Renders an object `Sendable` by wrapping in a lock
public struct ProtectedObject<Protected: AnyObject>: @unchecked Sendable {
    private let object: Protected
    private let locker: any LockingStrategy

    public init(object: Protected, locker: any LockingStrategy) {
        self.object = object
        self.locker = locker
    }

    public func withLock(block: (Protected) -> Void) {
        locker.withLock {
            block(object)
        }
    }

    public var unsafeObject: Protected {
        self.object
    }
}

extension ProtectedObject: Equatable {
    public static func == <L, R>(lhs: ProtectedObject<L>, rhs: ProtectedObject<R>) -> Bool {
        lhs.object === rhs.object
    }
}
