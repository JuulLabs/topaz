import Bluetooth

public struct CharacteristicEffect: BluetoothEffect {
    let name: EffectName

    public let peripheral: AnyPeripheral
    public let characteristic: Characteristic

    public init(_ name: EffectName, _ peripheral: AnyPeripheral, _ characteristic: Characteristic) {
        self.name = name
        self.peripheral = peripheral
        self.characteristic = characteristic
    }

    public var key: EffectKey {
        .characteristic(name, peripheral, characteristic)
    }
}

extension EffectKey {
    static func characteristic(_ name: EffectName, _ peripheral: AnyPeripheral, _ characteristic: Characteristic) -> Self {
        EffectKey(name: name, peripheral.identifier, characteristic.uuid, characteristic.instance)
    }
}
