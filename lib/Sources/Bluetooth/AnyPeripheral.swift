import Foundation

/**
 A type-erase peripheral to bridge between the universal and the existential type.
 */
@dynamicMemberLookup
public struct AnyPeripheral: Sendable {
    private let wrapped: any PeripheralProtocol

    public init(peripheral: some PeripheralProtocol) {
        wrapped = peripheral
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<any PeripheralProtocol, T>) -> T {
        wrapped[keyPath: keyPath]
    }
}

extension PeripheralProtocol {
    public func eraseToAnyPeripheral() -> AnyPeripheral {
        return AnyPeripheral(peripheral: self)
    }
}

extension AnyPeripheral {
    public func unerase<T: PeripheralProtocol>(as: T.Type) -> T? {
        return wrapped as? T
    }
}

extension AnyPeripheral: Identifiable {
    public var id: UUID { wrapped.identifier }
}

extension AnyPeripheral: Equatable {
    public static func == (lhs: AnyPeripheral, rhs: AnyPeripheral) -> Bool {
        _isEqual(lhs, rhs) ?? false
    }
}
