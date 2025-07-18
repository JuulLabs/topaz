import Foundation
import Helpers

public struct Peripheral: Sendable {
    public let peripheral: AnyProtectedObject
    public let id: UUID
    public let name: String?
    public var services: [Service]
    public var permissions: PeripheralPermissions

    public init(
        peripheral: AnyProtectedObject,
        id: UUID,
        name: String? = nil,
        services: [Service] = [],
        permissions: PeripheralPermissions = .init(allowedServices: .all)
    ) {
        self.id = id
        self.peripheral = peripheral
        self.name = name
        self.services = services
        self.permissions = permissions
    }

    public var connectionState: ConnectionState? {
        var state: ConnectionState?
        peripheral.withLock { (peripheral: AnyObject) in
            state = (peripheral as? PeripheralProtocol)?.connectionState
        }
        return state
    }

    public var isReadyToSendWriteWithoutResponse: Bool {
        var state: Bool?
        peripheral.withLock { (peripheral: AnyObject) in
            state = (peripheral as? PeripheralProtocol)?.isReadyToSendWriteWithoutResponse
        }
        return state ?? false
    }
}

public protocol PeripheralProtocol: AnyObject {
    var connectionState: ConnectionState { get }
    var isReadyToSendWriteWithoutResponse: Bool { get }
}
