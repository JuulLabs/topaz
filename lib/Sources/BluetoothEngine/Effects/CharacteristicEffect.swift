import Bluetooth

struct CharacteristicEffect: BluetoothEffect {
    let name: EffectName
    let peripheral: AnyPeripheral
    let characteristic: Characteristic

    init(_ name: EffectName, _ peripheral: AnyPeripheral, _ characteristic: Characteristic) {
        self.name = name
        self.peripheral = peripheral
        self.characteristic = characteristic
    }

    var key: EffectKey {
        .characteristic(name, peripheral, characteristic)
    }
}

extension EffectKey {
    static func characteristic(_ name: EffectName, _ peripheral: AnyPeripheral, _ characteristic: Characteristic) -> Self {
        EffectKey(name: name, peripheral.identifier, characteristic.uuid, characteristic.instance)
    }
}
