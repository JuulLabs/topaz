import Bluetooth

public struct PeripheralEvent: BluetoothEvent {
    public let name: EventName
    public let peripheral: Peripheral

    public init(_ name: EventName, _ peripheral: Peripheral) {
        self.name = name
        self.peripheral = peripheral
    }

    public var key: EventKey {
        .peripheral(name, peripheral)
    }
}

extension EventKey {
    public static func peripheral(_ name: EventName, _ peripheral: Peripheral) -> Self {
        EventKey(name: name, peripheral.id)
    }
}
