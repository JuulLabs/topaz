import Bluetooth

public struct CharacteristicEvent: BluetoothEvent {
    public let name: EventName
    public let peripheral: AnyPeripheral
    public let characteristic: Characteristic

    public init(_ name: EventName, _ peripheral: AnyPeripheral, _ characteristic: Characteristic) {
        self.name = name
        self.peripheral = peripheral
        self.characteristic = characteristic
    }

    public var key: EventKey {
        .characteristic(name, peripheral, characteristic)
    }
}

extension EventKey {
    public static func characteristic(_ name: EventName, _ peripheral: AnyPeripheral, _ characteristic: Characteristic) -> Self {
        EventKey(name: name, peripheral.identifier, characteristic.uuid, characteristic.instance)
    }
}
