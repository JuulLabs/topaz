import Bluetooth
import Foundation

public protocol BluetoothEffect: Sendable {
    var key: EffectKey { get }
}

public struct Effect<T: BluetoothEffect>: Sendable {
    private let effect: @Sendable () async throws -> T

    public init(effect: @escaping @Sendable () async throws -> T) {
        self.effect = effect
    }

    @discardableResult
    public func run() async throws -> T {
        return try await effect()
    }
}
