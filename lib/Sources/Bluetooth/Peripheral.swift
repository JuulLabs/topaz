import Foundation
import Helpers

public struct Peripheral: Sendable {
    public let peripheral: AnyProtectedObject
    public let id: UUID
    public let name: String?
    public var services: [Service]
    public var canSendWriteWithoutResponse: StateValue<Bool>

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
        self.canSendWriteWithoutResponse = StateValue(initialValue: false)
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
