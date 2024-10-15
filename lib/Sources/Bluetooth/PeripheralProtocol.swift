import Foundation

/**
 A protocol to shadow the system CBPeripheral type.
 The primary reason this exists is because CBPeripheral has no initializers which makes
 it impossible to write any kind of test or mock data for UI previews.
 */
public protocol PeripheralProtocol: Equatable, Sendable {
    var identifier: UUID { get }
    var connectionState: ConnectionState { get }
    var name: String? { get }
}
