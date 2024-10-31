import Foundation

/**
 A protocol to shadow the system CBPeripheral type.
 The primary reason this exists is because CBPeripheral has no initializers which makes
 it impossible to write any kind of test or mock data for UI previews.
 */
public protocol WrappedPeripheral: Equatable, Sendable {
    var _identifier: UUID { get }
    var _connectionState: ConnectionState { get }
    var _name: String? { get }
    var _services: [Service] { get }
}
