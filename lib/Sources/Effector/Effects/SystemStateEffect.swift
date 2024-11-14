import Bluetooth

public struct SystemStateEffect: Effect {
    public let systemState: SystemState

    public init(_ systemState: SystemState) {
        self.systemState = systemState
    }

    public var key: EffectKey {
        .systemState
    }
}

extension EffectKey {
    static let systemState = EffectKey(name: .systemState)
}
