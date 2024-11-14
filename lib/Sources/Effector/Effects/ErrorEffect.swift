import Bluetooth
import Foundation

public struct ErrorEffect: Effect {
    let name: EffectName

    public let key: EffectKey
    public let error: any Error

    public init(_ name: EffectName, _ key: EffectKey, _ error: any Error) {
        self.name = name
        self.key = key
        self.error = error
    }

    init(_ name: EffectName, _ peripheral: AnyPeripheral, _ error: any Error) {
        let key = EffectKey.peripheral(name, peripheral)
        self.init(name, key, error)
    }

    init(_ name: EffectName, _ peripheral: AnyPeripheral, _ characteristic: Characteristic, _ error: any Error) {
        let key = EffectKey.characteristic(name, peripheral, characteristic)
        self.init(name, key, error)
    }
}
