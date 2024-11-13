import Bluetooth
import Foundation

struct PeripheralEffect: BluetoothEffect {
    let name: EffectName
    let peripheral: AnyPeripheral

    init(_ name: EffectName, _ peripheral: AnyPeripheral) {
        self.name = name
        self.peripheral = peripheral
    }

    var key: EffectKey {
        .peripheral(name, peripheral)
    }
}

extension EffectKey {
    static func peripheral(_ name: EffectName, _ peripheral: AnyPeripheral) -> Self {
        EffectKey(name: name, peripheral.identifier)
    }
}
