import Bluetooth

struct SystemStateEffect: BluetoothEffect {
    let systemState: SystemState

    init(_ systemState: SystemState) {
        self.systemState = systemState
    }

    var key: EffectKey {
        .systemState
    }
}

extension EffectKey {
    static let systemState = EffectKey(name: .systemState)
}
