import Foundation
import Helpers

public struct Peripheral: Sendable {
    public let peripheral: AnyProtectedObject
    public let id: UUID
    public let name: String?
    public var services: [Service]

    public init(
        peripheral: AnyProtectedObject,
        id: UUID,
        name: String? = nil,
        services: [Service] = []
    ) {
        self.id = id
        self.peripheral = peripheral
        self.name = name
        self.services = services
    }

    public func withLock<T: AnyObject>(block: (T) -> Void) {
        (peripheral.wrapped as? ProtectedObject<T>)?.withLock(block: block)
    }

    public var connectionState: ConnectionState? {
        var state: ConnectionState?
        withLock { (peripheral: AnyObject) in
            state = (peripheral as? PeripheralProtocol)?.connectionState
        }
        return state
    }
}

public protocol PeripheralProtocol: AnyObject {
    var connectionState: ConnectionState { get }
}
