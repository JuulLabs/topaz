import Foundation

/**
 A type-erase peripheral to bridge between the universal and the existential type.
 */
public struct AnyPeripheral: Sendable {
    private let wrapped: any WrappedPeripheral

    public init(peripheral: some WrappedPeripheral) {
        wrapped = peripheral
    }
}

extension WrappedPeripheral {
    public func eraseToAnyPeripheral() -> AnyPeripheral {
        return AnyPeripheral(peripheral: self)
    }
}

extension AnyPeripheral {
    public func unerase<T: WrappedPeripheral>(as: T.Type) -> T? {
        return wrapped as? T
    }
}

extension AnyPeripheral: Identifiable {
    public var id: UUID { wrapped._identifier }
}

extension AnyPeripheral: Equatable {
    public static func == (lhs: AnyPeripheral, rhs: AnyPeripheral) -> Bool {
        _isEqual(lhs, rhs) ?? false
    }
}

// Accessors for surfacing the sterilized version of the wrapped peripheral
extension AnyPeripheral {
    public var identifier: UUID {
        wrapped._identifier
    }

    public var connectionState: ConnectionState {
        wrapped._connectionState
    }

    public var name: String? {
        wrapped._name
    }

    public var services: [Service] {
        wrapped._services
    }
}
