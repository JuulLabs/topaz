import Bluetooth
import Foundation

public struct PeripheralEffect: Effect {
    let name: EffectName

    public let peripheral: AnyPeripheral

    public init(_ name: EffectName, _ peripheral: AnyPeripheral) {
        self.name = name
        self.peripheral = peripheral
    }

    public var key: EffectKey {
        .peripheral(name, peripheral)
    }
}

extension EffectKey {
    static func peripheral(_ name: EffectName, _ peripheral: AnyPeripheral) -> Self {
        EffectKey(name: name, peripheral.identifier)
    }
}
